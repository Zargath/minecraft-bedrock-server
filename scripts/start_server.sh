#!/usr/bin/env bash

SERVER_PATH=/opt/minecraft-bedrock-server/

/usr/bin/screen -dmS mcbedrock /bin/bash -c "LD_LIBRARY_PATH=$SERVER_PATH ${SERVER_PATH}bedrock_server"
/usr/bin/screen -rD mcbedrock -X multiuser on
/usr/bin/screen -rD mcbedrock -X acladd root