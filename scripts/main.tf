resource "tls_private_key" "new-key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "app-key" {
  key_name   = "new-key"
  public_key = tls_private_key.new-key.public_key_openssh
}

resource "local_file" "new-key" {
  content  = tls_private_key.new-key.private_key_pem
  filename = "new-key.pem"

  provisioner "local-exec" {
    command = "chmod 600 ${self.filename}"
  }

}

resource "aws_instance" "kubernetes_master" {
  ami = "ami-04b70fa74e45c3917" 
  instance_type = "t2.micro" 
  key_name = "new-key"
  vpc_security_group_ids= ["sg-090308876f85665e4"]
  tags = {
    Name = "kubernetes_master"
  }
  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = tls_private_key.new-key.private_key_pem
    host     = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [ "echo 'wait to start instance' "]
  }
  provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_master.public_ip} > inventory "
  }
   provisioner "local-exec" {
   command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/k8s-master-setup.yml"
  } 
}

resource "aws_instance" "kubernetes_worker_1" {
  ami = "ami-04b70fa74e45c3917" 
  instance_type = "t2.micro" 
  key_name = "new-key"
  vpc_security_group_ids= ["sg-090308876f85665e4"]
  tags = {
    Name = "kubernetes_worker_1"
  }
  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = tls_private_key.new-key.private_key_pem
    host     = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [ "echo 'wait to start instance' "]
  }
  provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_worker_1.public_ip} > inventory "
  }
   provisioner "local-exec" {
   command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/k8s-worker-setup.yml"
  } 
  depends_on = [aws_instance.kubernetes_master]
}

resource "aws_instance" "kubernetes_worker_2" {
  ami = "ami-04b70fa74e45c3917" 
  instance_type = "t2.micro" 
  key_name = "new-key"
  vpc_security_group_ids= ["sg-090308876f85665e4"]
  tags = {
    Name = "kubernetes_worker_2"
  }
  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = tls_private_key.new-key.private_key_pem
    host     = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [ "echo 'wait to start instance' "]
  }
  provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_worker_2.public_ip} > inventory "
  }
   provisioner "local-exec" {
   command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/k8s-worker-setup.yml"
  } 
  depends_on = [aws_instance.kubernetes_worker_1]
}

resource "null_resource" "local_command" {
  
  provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_master.public_ip} > inventory "
  }

  provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/monitoring-deployment.yml"
  }

  provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/k8sdeploy.yml"
  }

  depends_on = [aws_instance.kubernetes_worker_2]
}

resource "aws_instance" "monitoring_server" {
  ami = "ami-04b70fa74e45c3917" 
  instance_type = "t2.micro" 
  key_name = "new-key"
  vpc_security_group_ids= ["sg-090308876f85665e4"]
  tags = {
    Name = "monitoring_server"
  }
  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = tls_private_key.new-key.private_key_pem
    host     = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [ "echo 'wait to start instance' "]
  }
  provisioner "local-exec" {
        command = " echo ${aws_instance.monitoring_server.public_ip} > inventory "
  }
   provisioner "local-exec" {
   command = "ansible-playbook /var/lib/jenkins/workspace/Healthcare/scripts/monitoring.yml"
  }
  depends_on = [null_resource.local_command]  
}
