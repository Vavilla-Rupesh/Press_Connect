const Database = require('../database');
require('dotenv').config();

async function runMigrations() {
  const database = new Database();
  
  try {
    console.log('Starting database migrations...');
    await database.initialize();
    console.log('Database migrations completed successfully!');
    console.log('Tables created:');
    console.log('- users');
    console.log('- oauth_tokens');
    console.log('- streams');
    console.log('- recordings');
    console.log('- snapshots');
    console.log('');
    console.log('You can now start the server with: npm start');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    await database.close();
  }
}

runMigrations();