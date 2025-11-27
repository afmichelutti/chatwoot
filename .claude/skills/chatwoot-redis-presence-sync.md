# Skill: Chatwoot Redis Presence Sync

## Description
Expert knowledge for diagnosing and fixing Redis presence desync issues where agent availability status in the database doesn't match what's stored in Redis cache.

## When to Use
- Agents manually set to "online" keep reverting to "offline"
- `auto_offline = false` but agents still show offline
- After using `update_all()` to change `auto_offline` or `availability` fields
- Agent status is correct in DB but wrong in the UI
- Redis cache has stale presence data

## Problem Overview

### Root Cause
When using ActiveRecord's `update_all()` method, **callbacks are bypassed**, including:

```ruby
# app/models/account_user.rb:41
after_save :update_presence_in_redis, if: :saved_change_to_availability?
```

This means:
- Database is updated ✅
- Redis is NOT updated ❌
- UI shows stale cached data from Redis

### Symptoms
1. Agent status correct in database query but wrong in UI
2. Agent set to "online" manually but shows "offline" in app
3. Status changes don't persist after page refresh
4. Multiple agents affected after bulk updates

## Solution: Manual Redis Sync

### Option 1: Sync Specific Users by Email

Use when only a few specific users are affected:

```ruby
# Rails Console
user_emails = [
  'user1@example.com',
  'user2@example.com',
  'user3@example.com'
]

user_emails.each do |email|
  user = User.find_by(email: email)
  next unless user

  # For each account the user belongs to
  user.account_users.where(account_id: 1).each do |au|
    # Force update in Redis
    OnlineStatusTracker.set_status(au.account_id, user.id, au.availability)
    puts "✅ #{user.name} - Status '#{au.availability}' updated in Redis"
  end
end
```

**When to use**:
- Small number of affected users (< 10)
- You know specific email addresses
- Quick targeted fix

### Option 2: Sync All Users for Specific Account

Use when entire account needs Redis sync:

```ruby
# Rails Console
account_id = 1

AccountUser.where(account_id: account_id).find_each do |au|
  OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
  puts "✅ User #{au.user_id} - Status '#{au.availability}' synced"
end

puts "\n✅ All #{AccountUser.where(account_id: account_id).count} agents synced for account #{account_id}"
```

**When to use**:
- After `update_all()` on entire account
- Multiple users affected
- Want to ensure complete sync
- **RECOMMENDED** for most cases

### Option 3: Nuclear Option - Clear Redis Completely

Use only when Redis data is completely corrupted:

```ruby
# Rails Console
account_id = 1

# Clear all presence data for account
Redis::Alfred.del("ONLINE_PRESENCE::#{account_id}::USERS")
Redis::Alfred.del("ONLINE_STATUS::#{account_id}")

puts "⚠️  Redis cleared for account #{account_id}"
puts "Agents will show offline until next heartbeat (20s) or manual sync"

# Optional: Immediately sync from DB
AccountUser.where(account_id: account_id).find_each do |au|
  OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
end
puts "✅ Redis resynced from database"
```

**When to use**:
- Redis data completely corrupted
- Testing/development environments
- Last resort in production
- **WARNING**: Briefly shows all agents offline

## Diagnostic Commands

### Check Database vs Redis Status

```ruby
# Rails Console
user = User.find_by(email: 'user@example.com')
au = user.account_users.find_by(account_id: 1)

puts "=== Database ==="
puts "auto_offline: #{au.auto_offline}"
puts "availability: #{au.availability}"

puts "\n=== Redis ==="
redis_status = OnlineStatusTracker.get_status(au.account_id, user.id)
puts "cached status: #{redis_status || 'NOT SET'}"

puts "\n=== Final Computed Status ==="
puts "user_availability_status: #{au.user_availability_status}"
```

### Check All Agents Status for Account

```ruby
# Rails Console
account_id = 1

puts "USER_ID | EMAIL | DB_AVAILABILITY | AUTO_OFFLINE | REDIS_STATUS | FINAL_STATUS"
puts "-" * 100

AccountUser.where(account_id: account_id).includes(:user).find_each do |au|
  user = au.user
  redis_status = OnlineStatusTracker.get_status(au.account_id, user.id)

  puts "#{user.id} | #{user.email} | #{au.availability} | #{au.auto_offline} | #{redis_status || 'NOT_SET'} | #{au.user_availability_status}"
end
```

### Verify Redis Keys Directly

```bash
# Redis CLI
redis-cli

# View all users with presence for account 1
ZRANGE "ONLINE_PRESENCE::1::USERS" 0 -1 WITHSCORES

# View availability status hash
HGETALL "ONLINE_STATUS::1"

# Check specific user (replace 123 with user_id)
ZSCORE "ONLINE_PRESENCE::1::USERS" 123
HGET "ONLINE_STATUS::1" 123
```

## Common Scenarios

### Scenario 1: Bulk Disable auto_offline

**What you did**:
```ruby
AccountUser.where(account_id: 1).update_all(auto_offline: false)
```

**Problem**: Callbacks not fired, Redis still has old data

**Solution**: Option 2 (sync all users for account)

---

### Scenario 2: Set Multiple Users Online

**What you did**:
```ruby
# Set users online in DB
AccountUser.where(user_id: [10, 20, 30]).update_all(availability: 'online')
```

**Problem**: Redis not updated, UI shows offline

**Solution**: Option 1 (sync specific users by email)

---

### Scenario 3: Change Single User Availability

**What you did**:
```ruby
user = User.find(123)
user.account_users.first.update_columns(availability: 'busy')
```

**Problem**: `update_columns()` also bypasses callbacks

**Solution**: Use `update!()` instead OR sync manually:
```ruby
# CORRECT WAY (triggers callbacks)
user.account_users.first.update!(availability: 'busy')

# OR manual sync after update_columns
au = user.account_users.first
OnlineStatusTracker.set_status(au.account_id, user.id, au.availability)
```

## Prevention Best Practices

### 1. Avoid Callback-Bypassing Methods

**Methods that BYPASS callbacks** (require manual Redis sync):
- `update_all()`
- `update_columns()`
- Direct SQL: `ActiveRecord::Base.connection.execute()`

**Methods that TRIGGER callbacks** (Redis auto-synced):
- `update()`
- `update!()`
- `save()`
- `save!()`

### 2. Use Proper Update Pattern

```ruby
# ❌ BAD (bypasses callbacks)
AccountUser.where(account_id: 1).update_all(auto_offline: false)

# ✅ GOOD (triggers callbacks, but slower)
AccountUser.where(account_id: 1).find_each do |au|
  au.update!(auto_offline: false)
end

# ✅ ACCEPTABLE (fast + manual sync)
AccountUser.where(account_id: 1).update_all(auto_offline: false)
AccountUser.where(account_id: 1).find_each do |au|
  OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
end
```

### 3. Create Rake Task for Common Operations

```ruby
# lib/tasks/agent_management.rake
namespace :chatwoot do
  desc 'Safely disable auto_offline for account'
  task :disable_auto_offline, [:account_id] => :environment do |_t, args|
    account_id = args[:account_id].to_i

    puts "Disabling auto_offline for account #{account_id}..."

    # Update database
    count = AccountUser.where(account_id: account_id).update_all(auto_offline: false)
    puts "✅ Updated #{count} records in database"

    # Sync Redis
    AccountUser.where(account_id: account_id).find_each do |au|
      OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
    end
    puts "✅ Synced Redis for account #{account_id}"
  end
end
```

**Usage**:
```bash
bundle exec rake chatwoot:disable_auto_offline[1]
```

## How Availability Status Works

### When auto_offline = true (Default)
```ruby
# app/models/concerns/availability_statusable.rb:23-29
def user_availability_status
  return availability unless auto_offline

  online_presence? ? (redis_status || availability) : 'offline'
end
```

**Logic**:
1. Check if user sent heartbeat in last 20 seconds (`online_presence?`)
2. If YES: Use Redis cached status OR DB availability
3. If NO: Force 'offline'

**Dependencies**: Database + Redis + WebSocket heartbeat

---

### When auto_offline = false
```ruby
def user_availability_status
  return availability  # Just return DB value
end
```

**Logic**:
1. Ignore Redis
2. Ignore heartbeat
3. Use ONLY database `availability` field

**Dependencies**: Database only (simpler, but less dynamic)

## Redis Architecture

### Key Structure

```
ONLINE_PRESENCE::{account_id}::USERS
  Type: Sorted Set
  Member: user_id (integer)
  Score: timestamp (Unix epoch)
  TTL: None (manually managed)

ONLINE_STATUS::{account_id}
  Type: Hash
  Key: user_id (string)
  Value: availability (online/busy/offline)
  TTL: None (manually managed)
```

### Data Flow

```
User Action in UI
  ↓
AccountUser.update!(availability: 'online')  [Database Write]
  ↓
after_save callback triggered
  ↓
update_presence_in_redis method
  ↓
OnlineStatusTracker.set_status(account_id, user_id, 'online')  [Redis Write]
  ↓
Redis keys updated:
  - ONLINE_PRESENCE::{account_id}::USERS → user_id added with current timestamp
  - ONLINE_STATUS::{account_id} → user_id => 'online'
  ↓
UI polls or receives WebSocket broadcast
  ↓
Agent shows as online ✅
```

### When update_all() Breaks This Flow

```
AccountUser.update_all(availability: 'online')  [Database Write]
  ↓
Callbacks SKIPPED ❌
  ↓
Redis NEVER updated ❌
  ↓
Database: availability = 'online' ✅
Redis: Still has old value (e.g., 'offline') ❌
  ↓
UI reads from Redis → Shows 'offline' ❌
```

## Related Skills

- [chatwoot-agent-presence.md](chatwoot-agent-presence.md) - Overall presence system architecture
- [auto_offline.md](../../docs/md/auto_offline.md) - Complete auto_offline documentation

## Key Files Reference

### Backend
- `lib/online_status_tracker.rb` - Redis operations
- `app/models/account_user.rb:41` - Callback definition
- `app/models/account_user.rb:79-81` - Redis update logic
- `app/models/concerns/availability_statusable.rb:23-29` - Status computation

### Redis
- `config/initializers/redis.rb` - Redis::Alfred configuration
- `lib/redis/alfred.rb` - Redis wrapper (if exists)

## Quick Reference Commands

```ruby
# Check if sync needed
au = AccountUser.find_by(user_id: 123, account_id: 1)
db_status = au.availability
redis_status = OnlineStatusTracker.get_status(1, 123)
puts "DB: #{db_status}, Redis: #{redis_status}, Match: #{db_status == redis_status}"

# Sync single user
OnlineStatusTracker.set_status(account_id, user_id, availability)

# Sync all users in account
AccountUser.where(account_id: 1).find_each do |au|
  OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
end

# Clear Redis for account
Redis::Alfred.del("ONLINE_PRESENCE::1::USERS")
Redis::Alfred.del("ONLINE_STATUS::1")
```

## Troubleshooting Checklist

- [ ] Verify `availability` value in `account_users` table
- [ ] Check Redis keys `ONLINE_PRESENCE::X::USERS` and `ONLINE_STATUS::X`
- [ ] Confirm `auto_offline` setting for affected users
- [ ] Check if `update_all()` or `update_columns()` was used
- [ ] Verify callbacks are enabled (not in migration context)
- [ ] Test with single user sync first before bulk operations
- [ ] Verify Redis connection is working (`Redis::Alfred.ping`)
- [ ] Check Rails logs for Redis errors
- [ ] Confirm account_id is correct
- [ ] Verify user_id exists in both DB and Redis

## Summary

**Problem**: Redis cache desync after using `update_all()` or `update_columns()`

**Solution**: Manually sync Redis using `OnlineStatusTracker.set_status()`

**Prevention**: Use `update!()` instead, or create rake tasks that handle both DB + Redis

**Best Practice**: Always sync Redis after bulk database operations on `availability` or `auto_offline` fields
