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
  ami             = "ami-0e001c9271cf7f3b9"
  instance_type   = "t2.micro"
  key_name        = "new-key"
  vpc_security_group_ids= ["sg-011b20abb569c9149"]
  tags = {
    Name = "kubernetes_master" 
  }

  provisioner "remote-exec" {
      inline = [ "echo 'wait to start instance' "]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.new-key.private_key_pem
    host        = self.public_ip
  }
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_master.public_ip} > inventory "
  }
   provisioner "local-exec" {
  	command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/kubernetes_master_setup.yaml"
  }
  provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/monitoring_setup.yaml"
  }
}

resource "aws_instance" "kubernetes_worker1" {
  ami             = "ami-0e001c9271cf7f3b9"
  instance_type   = "t2.micro"
  key_name        = "new-key"
  vpc_security_group_ids= ["sg-011b20abb569c9149"]
  tags = {
    Name = "kubernetes_worker1"
  }

  provisioner "remote-exec" {
      inline = [ "echo 'wait to start instance' "]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.new-key.private_key_pem
    host        = self.public_ip
  }
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_worker1.public_ip} > inventory "
  }
   provisioner "local-exec" {
       command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/kubernetes_worker_setup.yaml"
  }
  depends_on = [aws_instance.kubernetes_master]
}

resource "aws_instance" "kubernetes_worker2" {
  ami             = "ami-0e001c9271cf7f3b9"
  instance_type   = "t2.micro"
  key_name        = "new-key"
  vpc_security_group_ids= ["sg-011b20abb569c9149"]
  tags = {
    Name = "kubernetes_worker2"
  }

  provisioner "remote-exec" {
      inline = [ "echo 'wait to start instance' "]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.new-key.private_key_pem
    host        = self.public_ip
  }
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_worker2.public_ip} > inventory "
  }
   provisioner "local-exec" {
       command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/kubernetes_worker_setup.yaml"
  }
  depends_on = [aws_instance.kubernetes_worker1]
}

resource "null_resource" "local_command" {
  
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_master.public_ip} > inventory "
  }
   
   provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/monitoring_deployment.yaml"
  }

   provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/kubernetes_deployment.yaml"
  }
  depends_on = [aws_instance.kubernetes_worker2]

}
