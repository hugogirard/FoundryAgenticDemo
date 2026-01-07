import { Module } from "@nestjs/common";
import { QuestController } from "./quest.controller";
import { QuestRepository } from "./quest.repository";


@Module({
    controllers: [QuestController],
    providers: [QuestRepository]
})
export class QuestModule { }