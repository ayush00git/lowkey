import { appSchema, tableSchema } from '@nozbe/watermelondb'

export default appSchema({
  version: 1,
  tables: [
    tableSchema({
      name: 'peers',
      columns: [
        { name: 'uuid', type: 'string' },
        { name: 'public_key', type: 'string', isOptional: true },
        { name: 'last_seen_at', type: 'number' },
      ],
    }),
    tableSchema({
      name: 'messages',
      columns: [
        { name: 'peer_id', type: 'string', isIndexed: true },
        { name: 'content', type: 'string' },
        { name: 'type', type: 'string' }, // 'sdp' or 'ice'
        { name: 'created_at', type: 'number' },
      ],
    }),
  ],
})
