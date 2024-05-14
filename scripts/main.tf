resource "tls_private_key" "medicure-key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "app-key" {
  key_name   = "medicure-key"
  public_key = tls_private_key.medicure-key.public_key_openssh
}

resource "local_file" "medicure-key" {
  content  = tls_private_key.medicure-key.private_key_pem
  filename = "medicure-key.pem"

  provisioner "local-exec" {
    command = "chmod 600 ${self.filename}"
  }

}

resource "aws_instance" "kubernetes_master" {
  ami             = "ami-04b70fa74e45c3917"
  instance_type   = "t2.micro"
  key_name        = "medicure-key"
  vpc_security_group_ids= ["sg-090308876f85665e4"]
  tags = {
    Name = "kubernetes_master"
  }

  provisioner "remote-exec" {
      inline = [ "echo 'wait to start instance' "]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.medicure-key.private_key_pem
    host        = self.public_ip
  }
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_master.public_ip} > inventory"
  }
   provisioner "local-exec" {
  	command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/kubernetes_master_setup.yaml"
  }
   provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/monitoring_setup.yaml"
  }
  
}

resource "aws_instance" "kubernetes_worker1" {
  ami             = "ami-04b70fa74e45c3917"
  instance_type   = "t2.micro"
  key_name        = "medicure-key"
  vpc_security_group_ids= ["sg-090308876f85665e4"]
  tags = {
    Name = "kubernetes_worker1"
  }

  provisioner "remote-exec" {
      inline = [ "echo 'wait to start instance' "]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.medicure-key.private_key_pem
    host        = self.public_ip
  }
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_worker1.public_ip} > inventory"
  }
   provisioner "local-exec" {
       command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/kubernetes_worker_setup.yaml"
  }
  depends_on = [aws_instance.kubernetes_master]
}

resource "aws_instance" "kubernetes_worker2" {
  ami             = "ami-04b70fa74e45c3917"
  instance_type   = "t2.micro"
  key_name        = "medicure-key"
  vpc_security_group_ids= ["sg-090308876f85665e4"]
  tags = {
    Name = "kubernetes_worker2"
  }

  provisioner "remote-exec" {
      inline = [ "echo 'wait to start instance' "]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.medicure-key.private_key_pem
    host        = self.public_ip
  }
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_worker2.public_ip} > inventory"
  }
   provisioner "local-exec" {
       command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/kubernetes_worker_setup.yaml"
  }
  depends_on = [aws_instance.kubernetes_worker1]
}

resource "null_resource" "local_command" {
  
   provisioner "local-exec" {
        command = " echo ${aws_instance.kubernetes_master.public_ip} > inventory"
  }
   
   provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/monitoring_deployment.yaml"
  }

   provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Medicure/scripts/kubernetes_deployment.yaml"
  }
  depends_on = [aws_instance.kubernetes_worker2]

}
