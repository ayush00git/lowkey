import { Database } from '@nozbe/watermelondb'
import SQLiteAdapter from '@nozbe/watermelondb/adapters/sqlite'

import schema from './schema'

const adapter = new SQLiteAdapter({
  schema,
  dbName: 'lowkey_db',
  // jsi: true, // Only if you have JSI enabled
  onSetUpError: error => {
    // Database failed to load -- help the user!
    console.error('WatermelonDB setup error:', error)
  }
})

export const database = new Database({
  adapter,
  modelClasses: [
    // Post,
    // Comment,
  ],
})
