# sql-auto-installer

SQL Server Automated Installer Script (PowerShell)

This PowerShell script provides an automated way to install a SQL Server 2019 (or 2022 if you edit Version from $installParams) instance with custom configuration options using the dbatools module. It includes port configuration, filesystem setup, firewall rule creation, and optional SSMS installation.

⚠️ This script must be executed as Administrator and assumes the presence of SQL Server installation files locally.

🛠 Features

SQL Server 2019 or SQL Server 2022 installation using Install-DbaInstance

Dynamic or fixed TCP port configuration

Custom instance name, root path, and SA password

Automatic folder creation for Data, Log, TempDB, Backup

Optional installation of SQL Server Management Studio (SSMS)

Post-installation service and port validation

Logs everything to a timestamped .log file

🚀 Usage

.Install-SQLServer.ps1 \
    -RootPath "D:\\SQL2019" \
    -InstanceName "Test" \
    -Port 51433 \
    -SetupFilesPath "C:\\Setup" \
    -InstallSSMS \
    -SAPassword "YourStrong!Passw0rd"

📝Parameters

### Parameters

| Name             | Description                                              | Required | Default        |
|------------------|----------------------------------------------------------|----------|----------------|
| `RootPath`       | Base directory for SQL instance files                    | No       | `D:\SQL2019`   |
| `InstanceName`   | Name of the SQL Server instance                         | No       | `Test`         |
| `Port`           | TCP port to use for SQL Server                          | No       | Random dynamic |
| `SetupFilesPath` | Path containing SQL Server installer & optional SSMS    | No       | `C:\Setup`     |
| `InstallSSMS`    | Switch to optionally install SSMS                       | No       | *Not set*      |
| `SAPassword`     | Password for `sa` user (plaintext, for demo use only)   | Yes      | -              |


📦 Requirements

Windows with PowerShell 5.1+

Administrator privileges

Internet access (for downloading dbatools if not present)

Local copy of SQL Server setup files (e.g. setup.exe, SSMS-Setup.exe)

📄 Log Output

All execution steps and errors are written to:

SQLInstall_yyyyMMdd-HHmmss.log

⚠️ Disclaimer

This script is provided as-is for automation and learning purposes only.
Use at your own risk. The author is not responsible for any issues caused by the use or misuse of this script in production environments.

🪪 License

No license — use it freely! Consider buying the author a coffee, a beer, or a roll of 35mm film. Cheers! 🍻

![BallerinaCappucinnaCappuccinoCappucinoCappucinaBalletEllaGIF](https://github.com/user-attachments/assets/7fb5f76a-edf3-4e47-a662-e9a0f12acb4c)
