import { Model } from '@nozbe/watermelondb';
import { field, date } from '@nozbe/watermelondb/decorators';

export class Message extends Model {
  static table = 'messages';

  @field('message_id') message_id!: string;
  @field('sender_id') sender_id!: string;
  @field('ciphertext') ciphertext!: string;
  @date('expires_at') expires_at!: number;
}
