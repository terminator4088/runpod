#!/bin/bash

#####	Start Docker Cmd: /bin/bash -c 'if [ -z "$CUSTOM_COMMAND_EXECUTED" ]; then wget "https://raw.githubusercontent.com/terminator4088/runpod/main/install.sh" -O /setup.sh && chmod +x /setup.sh && /setup.sh; export CUSTOM_COMMAND_EXECUTED=1; fi; exec /bin/bash'

apt update
apt install -y vim

if [ -f /workspace/installed ]; then
  cd /workspace/stable-diffusion-webui
  python3 -u relauncher.py
  exit 0
fi

cd /workspace
apt -y install git-lfs

##Download orig_backup
apt -y install rclone

##Fresh SD Install
mkdir /workspace/stable-diffusion-webui
cd /workspace/stable-diffusion-webui

if [ -z "$A1111" ]; then
	echo "Installing VLAD"
	git clone https://github.com/vladmandic/automatic.git ./
else
	echo "Installing A1111"
	git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git ./
	git checkout tags/v1.3.2
	git clone https://github.com/Mikubill/sd-webui-controlnet.git ./extensions/sd-webui-controlnet
	#git clone https://github.com/d8ahazard/sd_dreambooth_extension.git ./extensions/sd_dreambooth_extension
	#git clone https://github.com/imrayya/stable-diffusion-webui-Prompt_Generator.git ./extensions/stable-diffusion-webui-Prompt_Generator
fi

#Download Models
#wget "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" -O "Stable-diffusion/vanila.safetensors" &&
cd /workspace
(mkdir /workspace/download;
cd /workspace/download;
mkdir Stable-diffusion;
mkdir Lora;
mkdir embeddings;
mkdir VAE;
wget "https://civitai.com/api/download/models/126688?type=Model&format=SafeTensor&size=full&fp=fp16" -O "Stable-diffusion/DreamShaper.safetensors";
#wget "https://civitai.com/api/download/models/128078?type=Model&format=SafeTensor&size=full&fp=fp32" -O "Stable-diffusion/Vanilla.safetensors";
#wget "https://civitai.com/api/download/models/134461?type=Model&format=SafeTensor&size=full&fp=fp16" -O "Stable-diffusion/SDVN6-RealXL.safetensors";
#wget "https://civitai.com/api/download/models/131960?type=VAE&format=SafeTensor" -O "VAE/TalmendoXL.safetensors";
#wget "https://civitai.com/api/download/models/135867?type=Model&format=SafeTensor" -O "Lora/Detail_Tweaker_XL.safetensors" ;
#wget "https://civitai.com/api/download/models/152309?type=Model&format=SafeTensor" -O "Lora/Artfull.safetensors" ;
#git clone https://huggingface.co/lllyasviel/sd_control_collection ./controlnet_models;
wget "https://huggingface.co/lllyasviel/sd_control_collection/blob/main/diffusers_xl_canny_small.safetensors" -O "controlnet_models/diffusers_xl_canny_small.safetensors" ;
touch download_finished) &> download.log &
#wget "https://civitai.com/api/download/models/15640?type=Model&format=SafeTensor&size=full&fp=fp16" -O "Stable-diffusion/Uber.safetensors" && \
#wget "https://civitai.com/api/download/models/17233?type=Model&format=SafeTensor&size=full&fp=fp16" -O "Stable-diffusion/AOM3A1B.safetensors" && \

#Define Copy Script
cd /workspace
cat <<EOT > copy_downloaded_models.sh
#!/bin/bash
cd /workspace
mkdir stable-diffusion-webui/models/embeddings/
mkdir stable-diffusion-webui/models/VAE/
mkdir stable-diffusion-webui/models/Lora/
mv download/Stable-diffusion/* stable-diffusion-webui/models/Stable-diffusion/
mv download/embeddings/* stable-diffusion-webui/models/embeddings/
mv download/Lora/* stable-diffusion-webui/models/Lora/
mv download/VAE/* stable-diffusion-webui/models/VAE/
if [ -z "$A1111" ]; then
	mv download/controlnet_models/* stable-diffusion-webui/extensions-builtin/sd-webui-controlnet/models/
else
	mv download/controlnet_models/* stable-diffusion-webui/extensions/sd-webui-controlnet/models/
fi
EOT
chmod +x copy_downloaded_models.sh


#Write necessary files
cd /workspace/stable-diffusion-webui
cat  <<EOT > relauncher.py
#!/usr/bin/python3
import os, time

n = 0
while True:
    print('Relauncher: Launching...')
    if n > 0:
        print(f'\tRelaunch count: {n}')
    launch_string = "/workspace/stable-diffusion-webui/webui.sh -f --listen --insecure"
    os.system(launch_string)
    print('Relauncher: Process is ending. Relaunching in 2s...')
    n += 1
    time.sleep(2)
EOT
chmod +x relauncher.py



#source /workspace/venv/bin/activate
python3 -u /workspace/stable-diffusion-webui/relauncher.py | while IFS= read -r line
do
	echo "--$line"
	if [[ "$line" == *"Available VAEs"* ]]; then
		pkill relauncher.py
		echo "Killed Relauncher as it was stuck at no models"
		
		while [[ ! -e /workspace/download/download_finished ]];do
			sleep 1
		done
		
		/workspace/copy_downloaded_models.sh
		echo "Copied Models"

  		touch /workspace/installed
  
		echo "Setup finished, launching SD :)"  
		python3 /workspace/stable-diffusion-webui/relauncher.py
	fi
done
