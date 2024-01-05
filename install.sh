#!/bin/bash

#####	Start Docker Cmd: /bin/bash -c 'if [ ! -f /setup.sh ]; then wget "https://raw.githubusercontent.com/terminator4088/runpod/main/install.sh" -O /setup.sh && chmod +x /setup.sh && /setup.sh; fi'

export A1111="True"

apt update
apt install -y vim

if [ -d /workspace/stable-diffusion-webui ]; then
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
 	#git checkout tags/v1.6.0

  	cd extensions
	git clone https://github.com/Mikubill/sd-webui-controlnet.git
	#git clone https://github.com/ahgsql/StyleSelectorXL
	#git clone https://github.com/imrayya/stable-diffusion-webui-Prompt_Generator.git
	#git clone https://github.com/IDEA-Research/DWPose
	git clone https://github.com/Uminosachi/sd-webui-inpaint-anything.git
	#git clone https://github.com/d8ahazard/sd_dreambooth_extension.git ./extensions/sd_dreambooth_extension
fi

if [ -z "$A1111" ]; then
	controlnet_path='/workspace/stable-diffusion-webui/extensions-builtin/sd-webui-controlnet/models/'
else
	controlnet_path='/workspace/stable-diffusion-webui/extensions/sd-webui-controlnet/models/'
fi

(
wget "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/diffusers_xl_depth_mid.safetensors" -P $controlnet_path ;
wget "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/diffusers_xl_canny_mid.safetensors" -P $controlnet_path ;
wget "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/ip-adapter_xl.pth" -P $controlnet_path ;
wget "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_blur.safetensors" -P $controlnet_path ;
wget "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/t2i-adapter_xl_openpose.safetensors" -P $controlnet_path ;
wget "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/thibaud_xl_openpose_256lora.safetensors" -P $controlnet_path ;
wget "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/sai_xl_sketch_256lora.safetensors" -P $controlnet_path ;
wget "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/sai_xl_recolor_256lora.safetensors" -P $controlnet_path ;
wget "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/sai_xl_depth_256lora.safetensors" -P $controlnet_path ;
wget "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/sai_xl_canny_256lora.safetensors" -P $controlnet_path ;
wget "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid_sdxl.bin" -P $controlnet_path ;

sleep 10
touch /workspace/download/control_finish) &> control_download.log &

(
cd /workspace/stable-diffusion-webui/models;
mkdir Stable-diffusion;
mkdir Lora;
mkdir embeddings;
mkdir VAE;
wget "https://civitai.com/api/download/models/198246?type=Model&format=SafeTensor&size=pruned&fp=fp16" -O "Stable-diffusion/TimeLessXL.safetensors";
wget "https://civitai.com/api/download/models/169740?type=Model&format=SafeTensor&size=full&fp=fp16" -O "Stable-diffusion/ZavyXL.safetensors";
wget "https://huggingface.co/segmind/SSD-1B/resolve/main/SSD-1B-A1111.safetensors?download=true" -O "Stable-diffusion/SSD-1B.safetensors";

wget "https://civitai.com/api/download/models/131960?type=VAE&format=SafeTensor" -O "VAE/TalmendoXL.safetensors";

wget "https://huggingface.co/latent-consistency/lcm-lora-sdxl/resolve/main/pytorch_lora_weights.safetensors?download=true" -O "Lora/LCM-SDXL.safetensors";
wget "https://huggingface.co/latent-consistency/lcm-lora-ssd-1b/resolve/main/pytorch_lora_weights.safetensors?download=true" -O "Lora/LCM-SSD-1B.safetensors";

wget "https://civitai.com/api/download/models/135867?type=Model&format=SafeTensor" -O "Lora/Detail_Tweaker_XL.safetensors" ;
wget "https://civitai.com/api/download/models/169002?type=Model&format=SafeTensor" -O "Lora/Artfull_Fractal.safetensors" ;
wget "https://civitai.com/api/download/models/152309?type=Model&format=SafeTensor" -O "Lora/Artfull_Base.safetensors" ;
wget "https://civitai.com/api/download/models/169041?type=Model&format=SafeTensor" -O "Lora/Schematics.safetensors" ;


sleep 10
touch /workspace/download/finish) &> download.log &

#Define Copy Job
(cd /workspace
mkdir stable-diffusion-webui/models/Stable-diffusion/
mkdir stable-diffusion-webui/models/embeddings/
mkdir stable-diffusion-webui/models/VAE/
mkdir stable-diffusion-webui/models/Lora/

if [ -z "$A1111" ]; then
	controlnet_path='stable-diffusion-webui/extensions-builtin/sd-webui-controlnet/models/'
else
	controlnet_path='stable-diffusion-webui/extensions/sd-webui-controlnet/models/'
fi

while [ ! -f /workspace/download/finish ]; do
	mv download/Stable-diffusion/* stable-diffusion-webui/models/Stable-diffusion/ &
	mv download/embeddings/* stable-diffusion-webui/models/embeddings/ &
	mv download/Lora/* stable-diffusion-webui/models/Lora/ &
	mv download/VAE/* stable-diffusion-webui/models/VAE/ &
done

while [ ! -f /workspace/download/control_finish ]; do
	if [ -d $controlnet_path ]; then
		mv download/controlnet_models/* $controlnet_path &
	fi

	sleep 4
done
) &> copy.log &


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
if [ -z "$A1111" ]; then
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
	
			echo "Setup finished, launching SD :)"  
			python3 /workspace/stable-diffusion-webui/relauncher.py
		fi
	done
else
	python3 -u /workspace/stable-diffusion-webui/relauncher.py
fi
