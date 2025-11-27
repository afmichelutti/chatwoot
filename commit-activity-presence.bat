@echo off
echo ========================================
echo   Committing Activity-Based Presence
echo ========================================
echo.

REM Add new files (Activity-Based Presence feature)
git add app/jobs/activity_based_presence_job.rb
git add app/jobs/update_agent_presence_job.rb
git add app/javascript/dashboard/routes/dashboard/settings/account/components/ActivityBasedPresence.vue
git add db/migrate/20250118000000_add_activity_based_presence_to_accounts.rb
git add db/migrate/20250118000001_set_auto_offline_to_true.rb
git add docs/activity-based-presence.md

REM Add modified files (Activity-Based Presence feature)
git add app/controllers/api/v1/accounts_controller.rb
git add app/models/message.rb
git add app/models/account.rb
git add app/javascript/dashboard/i18n/locale/en/generalSettings.json
git add app/javascript/dashboard/i18n/locale/pt_BR/generalSettings.json
git add app/javascript/dashboard/routes/dashboard/settings/account/Index.vue
git add app/views/api/v1/models/_account.json.jbuilder
git add config/schedule.yml

REM Add Dockerfile (updated for production)
git add Dockerfile

REM Add helper scripts
git add test_activity_job.rb
git add debug_callback.rb

echo.
echo Files staged for commit. Review changes:
echo.
git status

echo.
echo ========================================
echo Ready to commit!
echo ========================================
echo.
echo Run the following command to commit:
echo.
echo git commit -m "feat: Add Activity-Based Presence system
echo.
echo - Auto-manage agent availability based on message activity
echo - Immediate online status when sending messages
echo - Periodic offline check (every 1 minute)
echo - Configurable timeouts per account
echo - Auto-enable for all agents with opt-out option
echo - Web UI for configuration
echo - Performance optimized with async jobs
echo "
echo.
pause
