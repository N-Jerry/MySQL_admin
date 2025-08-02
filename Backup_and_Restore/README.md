
# 🛒 E-commerce Database Backup System

This project provides a **simple, secure backup and restore system** for a small e-commerce startup’s MySQL database (`ecommerce_db`).  
It is designed for a **single VPS with limited storage**, focusing on backing up the `orders` table and enabling **quick recovery** from accidental data loss.  
The system uses **encrypted credentials**, **compressed backups**, and **clear logs** for **reliability** and **auditability**.

---

## ✅ Features

- ⏰ Daily backups of `ecommerce_db` at 2 AM, compressed to save space.
- ♻️ Restore either the full database or just the `orders` table.
- 🔐 Secure MySQL credentials using a login path.
- 🗑️ 7-day retention policy to manage disk usage.
- 📝 Detailed logs for both backup and restore operations.

---

## 🧰 Prerequisites

- ✅ MySQL 8.0 is installed.
- 🐧 Using Oracle Linux (or any similar Linux distro).
- 📦 Required packages: `mysql-client`, `gzip`.
- 💾 At least 100 MB of free disk space in `/var/backups/mysql`.
- 👤 A MySQL admin user (e.g., `root`) for setup tasks.

---

## ⚙️ Setup

### 1. Create Database and Table

Set up the `ecommerce_db` database with a sample `orders` table:

```bash
mysql -u root -p
```

Then run the SQL script:

```sql
-- In MySQL shell
source create_ecommerce_db.sql;
```

### 2. Set Up Backup User

```sql
CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON ecommerce_db.* TO 'backup_user'@'localhost';
FLUSH PRIVILEGES;
```

### 3. Configure Login Path

```bash
sudo -u mysql mysql_config_editor set --login-path=backup --host=localhost --user=backup_user --password
```

> 💡 Enter `secure_password` when prompted.

### 4. Install Scripts

```bash
sudo cp backup.sh restore.sh /usr/local/bin/
sudo chmod 700 /usr/local/bin/backup.sh /usr/local/bin/restore.sh
sudo chown mysql:mysql /usr/local/bin/backup.sh /usr/local/bin/restore.sh
```

Create necessary directories and logs:

```bash
sudo mkdir -p /var/backups/mysql
sudo touch /var/log/mysql_backup.log /var/log/mysql_restore.log
sudo chown mysql:mysql /var/backups/mysql /var/log/mysql_backup.log /var/log/mysql_restore.log
sudo chmod 600 /var/log/mysql_backup.log /var/log/mysql_restore.log
```

### 5. Schedule Backups

```bash
sudo crontab -u mysql -e
```

Add this line:

```cron
0 2 * * * /bin/bash /usr/local/bin/backup.sh
```

---

## 🚀 Usage

### Backup

```bash
sudo -u mysql bash /usr/local/bin/backup.sh
```

> Creates file like: `/var/backups/mysql/ecommerce_db-YYYYMMDD_HHMMSS.sql.gz`

### Restore Full Database

```bash
sudo -u mysql bash /usr/local/bin/restore.sh /path/to/backup.sql.gz
```

### Restore Only the Orders Table

```bash
sudo -u mysql bash /usr/local/bin/restore.sh /path/to/backup.sql.gz orders
```

### View Logs

```bash
cat /var/log/mysql_backup.log
cat /var/log/mysql_restore.log
```

---

## 🧪 Recovery Demo

### Drop the table:

```bash
sudo -u mysql mysql --login-path=backup -e "DROP TABLE ecommerce_db.orders;"
```

### Restore:

```bash
sudo -u mysql bash /usr/local/bin/restore.sh /var/backups/mysql/ecommerce_db-YYYYMMDD_HHMMSS.sql.gz orders
```

### Verify:

```bash
sudo -u mysql mysql --login-path=backup -e "SELECT * FROM ecommerce_db.orders;"
```

---

## 📌 Notes

- 🔐 Credentials are encrypted in `~/.mylogin.cnf`.
- 💾 Backups are compressed and auto-deleted after 7 days.
- 🔗 Foreign key constraints are handled during restores.
- ⚠️ For larger DBs, table-level restore requires more advanced parsing.

---

## 🛠️ Troubleshooting

| Issue             | Solution                                                                 |
|------------------|--------------------------------------------------------------------------|
| Access Denied     | Verify login path and user privileges.                                  |
| File Missing      | Confirm backup file exists in `/var/backups/mysql`.                     |
| Disk Space        | Check with `df -h /var/backups/mysql`.                                  |
