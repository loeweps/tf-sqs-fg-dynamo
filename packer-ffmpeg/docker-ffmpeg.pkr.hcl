
packer {
  required_plugins {
    docker = {
      version = ">= 1.0.9"
      source = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "ffmpeg" {
  image = "jrottenberg/ffmpeg"
}

build {
  sources = ["docker.ffmpeg"]
}

build {
  name        = "ffmpeg-build"
  source "source.docker.ffmpeg" { 
  changes = [
    "RUN apt-get update && apt-get install python-dev python-pip -y && apt-get clean",
    "RUN pip install awscli",
    "WORKDIR /tmp/workdir",
    "COPY copy_thumbs.sh /tmp/workdir"
  ]
}
  
  


  provisioner "shell" {
    inline = [
      "ffmpeg -i ${var.input_video_file_url} -ss ${var.position_time_duration} -vframes 1 -vcodec png -an -y ${var.output_thumbs_file_name}",
      "./copy_thumbs.sh"
    ]
  }
}