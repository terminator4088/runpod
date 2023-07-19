#!/bin/bash

#####		/bin/bash -c "/workspace/init.sh; exec /bin/bash"

cd /workspace
apt update
apt -y install vim git-lfs

##Download orig_backup
apt -y install rclone

##Fresh SD Install
mkdir /workspace/stable-diffusion-webui
cd /workspace/stable-diffusion-webui

git clone https://github.com/vladmandic/automatic.git ./
# git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git ./
# git checkout tags/v1.3.2
# git clone https://github.com/Mikubill/sd-webui-controlnet.git ./extensions/sd-webui-controlnet
# git clone https://github.com/d8ahazard/sd_dreambooth_extension.git ./extensions/sd_dreambooth_extension
# git clone https://github.com/imrayya/stable-diffusion-webui-Prompt_Generator.git ./extensions/stable-diffusion-webui-Prompt_Generator



#Download Models
#wget "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" -O "Stable-diffusion/vanila.safetensors" &&
mkdir /workspace/download && \
cd /workspace/download && \
mkdir Stable-diffusion && \
mkdir Lora && \
mkdir embeddings && \
mkdir controlnet_models && \
mkdir VAE && \
wget "https://civitai.com/api/download/models/15640?type=Model&format=SafeTensor&size=full&fp=fp16" -O "Stable-diffusion/uber.safetensors" && \
wget "https://civitai.com/api/download/models/7543?type=Model&format=SafeTensor&size=full&fp=fp16" -O "Stable-diffusion/Chillout.safetensors" && \
wget "https://civitai.com/api/download/models/80869?type=Model&format=PickleTensor" -O "VAE/840k.pt" && \
wget "https://civitai.com/api/download/models/67485?type=Model&format=SafeTensor" -O "Lora/POV_missionary.safetensors" && \
wget "https://civitai.com/api/download/models/77169?type=Model&format=PickleTensor" -O "embeddings/BadDream.pt" && \
wget "https://civitai.com/api/download/models/77173?type=Model&format=PickleTensor" -O "embeddings/UnrealisticDream.pt" && \
wget "https://civitai.com/api/download/models/82745?type=Negative&format=Other" -O "embeddings/CyberRealistic.pt" && \
git clone https://huggingface.co/lllyasviel/ControlNet-v1-1 ./controlnet_models && \
touch download_finished &> download.log &

#Define Copy Script
cd /workspace
cat <<EOT > copy_downloaded_models.sh
#!/bin/bash
cd /workspace
mkdir stable-diffusion-webui/models/embeddings
mkdir stable-diffusion-webui/models/VAE
mv download/Stable-diffusion/* stable-diffusion-webui/models/Stable-diffusion
mv download/embeddings/* stable-diffusion-webui/models/embeddings
mv download/Lora/* stable-diffusion-webui/models/Lora
mv download/VAE/* stable-diffusion-webui/VAE
mv download/controlnet_models/* stable-diffusion-webui/extensions-builtin/sd-webui-controlnet/models
EOT
chmod +x copy_downloaded_models.sh

#Define Start Script
cd /workspace
cat <<EOT > start.sh
#!/bin/bash
apt update
apt install -y vim
cd stable-diffusion-webui
python3 relauncher.py
EOT
chmod +x start.sh

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
    launch_string = "/workspace/stable-diffusion-webui/webui.sh -f --listen"
    os.system(launch_string)
    print('Relauncher: Process is ending. Relaunching in 2s...')
    n += 1
    time.sleep(2)
EOT
chmod +x relauncher.py



#source /workspace/venv/bin/activate
python3 -u /workspace/stable-diffusion-webui/relauncher.py | while IFS= read -r line
do
	if [[ "$line" == *"Available VAEs"* ]]; then
		pkill relauncher.py
		echo "Killed Relauncher as it was stuck at no models"
		
		while [[ ! -e /workspace/download/download_finished ]];do
			sleep 1
		done
		
		./workspace/copy_downloaded_models.sh
		echo "Copied Models"

  
		echo "Setup finished, launching SD :)"  
		python3 /workspace/stable-diffusion-webui/relauncher.py
	fi
done
