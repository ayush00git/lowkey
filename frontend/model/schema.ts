import { appSchema, tableSchema } from '@nozbe/watermelondb';

export const schema = appSchema({
  version: 1,
  tables: [
    tableSchema({
      name: 'messages',
      columns: [
        { name: 'message_id', type: 'string' },
        { name: 'sender_id', type: 'string' },
        { name: 'ciphertext', type: 'string' },
        { name: 'expires_at', type: 'number' },
      ],
    }),
  ],
});
