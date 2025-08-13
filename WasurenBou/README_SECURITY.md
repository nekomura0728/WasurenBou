# Security Configuration Guide

## AdMob Configuration

### ⚠️ IMPORTANT SECURITY NOTICE
AdMob configuration files containing sensitive publisher IDs and app IDs have been removed from version control for security reasons.

### Setup Instructions

1. **Create AdMob Configuration File**
   ```bash
   cp AdMobConfig.template WasurenBou/WasurenBou/Services/AdMobConfig.swift
   ```

2. **Fill in Your Actual AdMob Values**
   Edit `AdMobConfig.swift` and replace the placeholder values:
   - `appID`: Your AdMob App ID
   - `bannerUnitID`: Your AdMob Banner Unit ID
   - `publisherID`: Your Publisher ID for app-ads.txt

3. **Update AdMobService.swift**
   Ensure the service uses the configuration:
   ```swift
   import AdMobConfig
   
   let appID = AppConfig.isDebugBuild ? AdMobConfig.TestIDs.appID : AdMobConfig.appID
   ```

### app-ads.txt Configuration

The `app-ads.txt` file should be hosted on your support website, not in the repository:

1. **Create app-ads.txt** on your support website root:
   ```
   google.com, [YOUR_PUBLISHER_ID], DIRECT, f08c47fec0942fa0
   ```

2. **Host Location**: `https://your-support-site.com/app-ads.txt`

3. **Verify Access**: Ensure the file is accessible via HTTPS

### Files Excluded from Git
- `AdMobConfig.swift` (contains sensitive IDs)
- `AdMob_Setup_Guide.md` (contains sensitive documentation)
- `ADMOB_SETUP.md` (contains sensitive setup info)
- `app-ads.txt` (contains publisher information)

### Development vs Production
- **Debug builds**: Automatically use Google's test Ad IDs
- **Release builds**: Use your actual production Ad IDs
- **Configuration**: Managed through `AdMobConfig.swift`

### Security Best Practices
1. Never commit actual AdMob IDs to version control
2. Use environment variables for CI/CD deployments
3. Keep sensitive configuration files in `.gitignore`
4. Host app-ads.txt on your support website, not in the repository
5. Review all commits to ensure no sensitive data is included