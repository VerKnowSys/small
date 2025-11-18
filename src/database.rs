use crate::*;
use anyhow::Result;
use rusqlite::{Connection, params};
use serde::{Deserialize, Serialize};
use std::{
    path::Path,
    sync::{Arc, Mutex},
};


#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct History {
    pub content: String,
    pub timestamp: i64,
    pub file: String,
    pub uuid: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueueItem {
    pub local_file: String,
    pub remote_file: String,
    pub uuid: String,
}

#[derive(Debug)]
pub struct Database {
    conn: Arc<Mutex<Connection>>,
}

impl Database {
    pub fn new<P: AsRef<Path>>(db_path: P) -> Result<Self> {
        // Ensure parent directory exists
        if let Some(parent) = db_path.as_ref().parent() {
            std::fs::create_dir_all(parent)?;
        }

        let conn = Connection::open(db_path)?;
        let db = Database {
            conn: Arc::new(Mutex::new(conn)),
        };
        db.init_schema()?;
        Ok(db)
    }


    fn init_schema(&self) -> Result<()> {
        let conn = self.conn.lock().unwrap();

        conn.execute(
            "CREATE TABLE IF NOT EXISTS history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                file TEXT NOT NULL,
                uuid TEXT NOT NULL UNIQUE
            )",
            [],
        )?;

        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_history_timestamp ON history(timestamp)",
            [],
        )?;

        conn.execute(
            "CREATE TABLE IF NOT EXISTS queue (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                local_file TEXT NOT NULL,
                remote_file TEXT NOT NULL,
                uuid TEXT NOT NULL UNIQUE
            )",
            [],
        )?;

        Ok(())
    }


    pub fn add_to_queue(&self, item: &QueueItem) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute(
            "INSERT OR IGNORE INTO queue (local_file, remote_file, uuid) VALUES (?1, ?2, ?3)",
            params![&item.local_file, &item.remote_file, &item.uuid],
        )?;
        Ok(())
    }


    pub fn get_queue(&self) -> Result<Vec<QueueItem>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT local_file, remote_file, uuid FROM queue")?;
        let items = stmt
            .query_map([], |row| {
                Ok(QueueItem {
                    local_file: row.get(0)?,
                    remote_file: row.get(1)?,
                    uuid: row.get(2)?,
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(items)
    }


    pub fn remove_from_queue(&self, uuid: &str) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute("DELETE FROM queue WHERE uuid = ?1", params![uuid])?;
        Ok(())
    }


    pub fn add_history(&self, history: &History) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute(
            "INSERT OR IGNORE INTO history (content, timestamp, file, uuid) VALUES (?1, ?2, ?3, ?4)",
            params![&history.content, &history.timestamp, &history.file, &history.uuid],
        )?;
        Ok(())
    }


    pub fn get_history(&self, limit: Option<usize>) -> Result<Vec<History>> {
        let conn = self.conn.lock().unwrap();
        let query = if let Some(lim) = limit {
            format!(
                "SELECT content, timestamp, file, uuid FROM history ORDER BY timestamp DESC LIMIT {}",
                lim
            )
        } else {
            "SELECT content, timestamp, file, uuid FROM history ORDER BY timestamp DESC"
                .to_string()
        };

        let mut stmt = conn.prepare(&query)?;
        let items = stmt
            .query_map([], |row| {
                Ok(History {
                    content: row.get(0)?,
                    timestamp: row.get(1)?,
                    file: row.get(2)?,
                    uuid: row.get(3)?,
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(items)
    }


    pub fn dump_to_file<P: AsRef<Path>>(&self, path: P) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        let mut backup_conn = Connection::open(&path)?;

        let backup = rusqlite::backup::Backup::new(&conn, &mut backup_conn)?;
        backup.run_to_completion(5, std::time::Duration::from_millis(250), None)?;

        info!("Database dumped to: {:?}", path.as_ref());
        Ok(())
    }
}
