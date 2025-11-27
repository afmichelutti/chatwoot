# Skill: Chatwoot Agent Presence & Auto Offline

## Description
Expert knowledge on Chatwoot's agent presence system, auto_offline feature, and troubleshooting online/offline status issues.

## When to Use
- Agent status issues (stuck online/offline, flickering status)
- Problems with auto_offline feature
- WebSocket/ActionCable connection issues
- pubsub_token problems
- Redis presence tracking issues

## Key Concepts

### 1. Auto Offline Feature
- **Field**: `auto_offline` (boolean) in `account_users` table
- **Default**: `true`
- **Location**: `app/models/account_user.rb:7`

#### Behavior
| auto_offline | Behavior |
|--------------|----------|
| `true` (default) | Agent automatically marked **offline** when heartbeat stops for >20s |
| `false` | Agent **never** marked offline automatically. Status from `availability` field only |

### 2. Presence System Architecture

#### Frontend (Heartbeat)
- **Interval**: Every **20 seconds**
- **File**: `app/javascript/shared/helpers/BaseActionCableConnector.js`
- **Action**: Sends signal via WebSocket (`update_presence`)

#### Backend (Tracking)
- **Service**: `OnlineStatusTracker` (`lib/online_status_tracker.rb`)
- **Storage**: Redis Sorted Sets
- **Duration**: `PRESENCE_DURATION` env var (default: 20 seconds)

#### Redis Keys
```
ONLINE_PRESENCE::{account_id}::USERS
  → Sorted Set: user_id (member) + timestamp (score)

ONLINE_STATUS::{account_id}
  → Hash: user_id → availability (online/busy/offline)
```

### 3. Availability Logic
**File**: `app/models/concerns/availability_statusable.rb:23-29`

```ruby
def user_availability_status
  return availability unless auto_offline  # auto_offline = false

  # auto_offline = true (default)
  online_presence? ? (redis_status || availability) : 'offline'
end
```

### 4. pubsub_token
- **Purpose**: Authenticates WebSocket (ActionCable) connections
- **Location**: `users.pubsub_token` field
- **Rotation**: Only on password change (see `app/models/concerns/pubsubable.rb:17-18`)
- **Critical**: Old tokens cause connection failures

## Common Issues & Solutions

### Issue 1: Agent Flickering Online/Offline

**Symptoms**: Logged-out agent alternates between online/offline constantly

**Root Cause**:
1. Old WebSocket sessions still active
2. pubsub_token not invalidated
3. Multiple sessions sending conflicting presence data

**Solution**:
```ruby
# Rails Console
user = User.find_by(email: 'user@example.com')

# Regenerate token (invalidates old connections)
user.regenerate_pubsub_token
user.save!

# Clear Redis
user.account_users.each do |au|
  OnlineStatusTracker.set_status(au.account_id, user.id, 'offline')
end
```

**Or use rake task**:
```bash
bundle exec rake chatwoot:cleanup_agent_presence USER_EMAIL=user@example.com
```

### Issue 2: All Agents Offline After Token Regeneration

**Symptoms**: After regenerating tokens, all agents show offline

**Root Cause**:
1. Tokens regenerated in DB
2. Users still logged in with old tokens in browser memory
3. ActionCable fails to connect
4. No heartbeat sent → all appear offline

**Solution**: Users must logout/login to reload new tokens from DB

**Temporary Workaround**:
```ruby
# Set auto_offline = false temporarily
AccountUser.where(account_id: 1).update_all(auto_offline: false)

# Manually set status in Redis for active users
OnlineStatusTracker.set_status(account_id, user_id, 'online')
```

### Issue 3: Agent Offline During Active Use

**Possible Causes**:
1. Heartbeat not being sent (WebSocket error)
2. `PRESENCE_DURATION` too short
3. Intermittent network issues

**Solution**:
- Check browser console for WebSocket errors
- Increase `PRESENCE_DURATION` if needed
- Verify connection stability

## Maintenance Tasks

### Created Rake Tasks
**File**: `lib/tasks/cleanup_agent_presence.rake`

```bash
# Cleanup specific agent
bundle exec rake chatwoot:cleanup_agent_presence USER_EMAIL=user@example.com

# Cleanup all problematic agents (auto_offline=true + availability=online)
bundle exec rake chatwoot:cleanup_agent_presence

# Force ALL agents offline in Redis
bundle exec rake chatwoot:force_all_agents_offline

# Regenerate tokens for specific account
bundle exec rake chatwoot:regenerate_account_tokens ACCOUNT_ID=1
```

## Database Operations

### Check Configuration
```sql
-- Distribution of auto_offline
SELECT auto_offline, COUNT(*)
FROM account_users
GROUP BY auto_offline;

-- Details by account
SELECT
  account_id,
  COUNT(*) as total_agents,
  SUM(CASE WHEN auto_offline THEN 1 ELSE 0 END) as with_auto_offline,
  SUM(CASE WHEN NOT auto_offline THEN 1 ELSE 0 END) as without_auto_offline
FROM account_users
GROUP BY account_id;
```

### Update Configuration
```sql
-- Enable auto_offline for all
UPDATE account_users SET auto_offline = true;

-- Enable for specific account
UPDATE account_users SET auto_offline = true WHERE account_id = 1;
```

### Rails Console
```ruby
# Update all
AccountUser.update_all(auto_offline: true)

# Update by account
AccountUser.where(account_id: 1).update_all(auto_offline: true)

# Update specific agent
user = User.find_by(email: 'agent@example.com')
AccountUser.where(user_id: user.id).update_all(auto_offline: true)
```

## Redis Debugging

```bash
# Connect to Redis
redis-cli

# View presence for account
ZRANGE "ONLINE_PRESENCE::1::USERS" 0 -1 WITHSCORES

# View availability status
HGETALL "ONLINE_STATUS::1"

# Clear presence (force re-sync)
DEL "ONLINE_PRESENCE::1::USERS"
DEL "ONLINE_STATUS::1"
```

## ActionCable Initialization Flow

1. User logs in → `currentUser` loaded with `pubsub_token`
2. `App.vue:122-126` → ActionCable initialized with token
3. WebSocket connects to server
4. Every 20s: `BaseActionCableConnector` sends heartbeat
5. Backend: `RoomChannel` updates Redis presence
6. Every X seconds: Backend broadcasts `presence.update` event
7. Frontend: `actionCable.js:58-63` updates agent status

**Critical**: If `pubsub_token` is invalid → ActionCable fails → No heartbeat → Agent offline

## Key Files Reference

### Backend
- `lib/online_status_tracker.rb` - Presence tracking service
- `app/channels/room_channel.rb` - WebSocket handler
- `app/models/concerns/availability_statusable.rb` - Status logic
- `app/models/concerns/pubsubable.rb` - Token management
- `app/models/account_user.rb` - Model with auto_offline field

### Frontend
- `app/javascript/shared/helpers/BaseActionCableConnector.js` - Heartbeat (20s)
- `app/javascript/dashboard/helper/actionCable.js` - Event handlers
- `app/javascript/dashboard/App.vue` - ActionCable initialization

### Documentation
- `docs/md/auto_offline.md` - Comprehensive guide

## Best Practices

1. **Don't regenerate tokens in production** without warning users
2. **Use auto_offline=true** for most agents (better UX)
3. **Use auto_offline=false** only for:
   - Admins who need 24/7 availability
   - Agents with unstable internet
   - Integration accounts
4. **Monitor Redis** for presence issues
5. **Check WebSocket connections** in browser console

## Environment Variables

```bash
# Presence duration (seconds)
PRESENCE_DURATION=20  # Default
```

## Troubleshooting Checklist

- [ ] Check `auto_offline` setting in DB
- [ ] Verify WebSocket connection in browser console
- [ ] Check Redis keys for presence data
- [ ] Verify `pubsub_token` is valid
- [ ] Check `PRESENCE_DURATION` environment variable
- [ ] Look for ActionCable errors in Rails logs
- [ ] Verify `currentAccountId` is defined in frontend
- [ ] Check if multiple browser tabs are open
