import { ApiProperty } from '@nestjs/swagger';

export class Enrollement {

    @ApiProperty({ description: 'The ID of the quest to enroll in' })
    questId: string;

    @ApiProperty({ description: 'The name of the adventurer' })
    adventurerName: string;
}