# Create a VPC
resource "aws_vpc" "proj-jenk" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = true
  
  tags = {
    Name = var.Name
  }
}


# public subnet 1
resource "aws_subnet" "proj-jenk-public-sub1" {
  vpc_id     = aws_vpc.proj-jenk.id
  cidr_block = var.proj-jenk-public-sub1-cidr_block
  availability_zone = var.proj-jenk-public-sub1-AZ

  tags = {
    Name = var.pub-sub1-Name
  }
}

# public subnet 2
resource "aws_subnet" "proj-jenk-public-sub2" {
  vpc_id     = aws_vpc.proj-jenk.id
  cidr_block = var.proj-jenk-public-sub2-cidr_block
  availability_zone = var.proj-jenk-public-sub2-AZ

  tags = {
    Name = var.pub-sub2-Name
  }
}

# private subnet 1
resource "aws_subnet" "proj-jenk-private-sub1" {
  vpc_id     = aws_vpc.proj-jenk.id
  cidr_block = var.proj-jenk-private-sub1-cidr_block
  availability_zone = var.proj-jenk-private-sub1-AZ

  tags = {
    Name = var.private-sub1-Name
  }
}

# private subnet 2
resource "aws_subnet" "proj-jenk-private-sub2" {
  vpc_id     = aws_vpc.proj-jenk.id
  cidr_block = var.proj-jenk-private-sub2-cidr_block
  availability_zone = var.private-sub2-AZ

  tags = {
    Name = var.priv-sub2-Name
  }
}

# public route table
resource "aws_route_table" "proj-jenk-public-route-table" {
  vpc_id = aws_vpc.proj-jenk.id

  tags = {
    Name = var.public-route-table-Name
  }
 }

# private route table
resource "aws_route_table" "proj-jenk-private-route-table" {
  vpc_id = aws_vpc.proj-jenk.id

  tags = {
    Name = var.private-route-table-Name
  }
  }

# public route table association 1
resource "aws_route_table_association" "proj-jenk-public-route-table-association1" {
  subnet_id      = aws_subnet.proj-jenk-public-sub1.id
  route_table_id = aws_route_table.proj-jenk-public-route-table.id
}

# public route table association 2
resource "aws_route_table_association" "proj-jenk-public-route-table-association2" {
  subnet_id      = aws_subnet.proj-jenk-public-sub2.id
  route_table_id = aws_route_table.proj-jenk-public-route-table.id
}

# private route table association 1
resource "aws_route_table_association" "proj-jenk-private-route-table-association1" {
  subnet_id      = aws_subnet.proj-jenk-private-sub1.id
  route_table_id = aws_route_table.proj-jenk-private-route-table.id
}

# private route table association 2
resource "aws_route_table_association" "proj-jenk-private-route-table-association2" {
  subnet_id      = aws_subnet.proj-jenk-private-sub2.id
  route_table_id = aws_route_table.proj-jenk-private-route-table.id
}

# internet gateway to communicate with public route table
resource "aws_internet_gateway" "proj-jenk-igw" {
  vpc_id = aws_vpc.proj-jenk.id

  tags = {
    Name = var.igw-Name
  }
}

# internet gateway association 
resource "aws_route" "proj-jenk-igw-association" {
 route_table_id = aws_route_table.proj-jenk-public-route-table.id
  destination_cidr_block    = var.destination-cidr_block
  gateway_id                = aws_internet_gateway.proj-jenk-igw.id
}


/*# provision elastic IP for public NAT Gateway 
resource "aws_eip" "proj-jenk-EIP" {
    vpc = true
    depends_on                = [aws_internet_gateway.proj-jenk-igw]
  tags = {
    Name = var.eip-Name
  }
}

# public NAT gateway for private route table/subnets
resource "aws_nat_gateway" "proj-jenk-Nat-gateway" {
  allocation_id = aws_eip.proj-jenk-EIP.id
   subnet_id      = aws_subnet.proj-jenk-public-sub2.id

  tags = {
    Name = var.NAT-Name
  }
}  

 /* # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.example] */

/*# NAT gateway to associate with private route table
resource "aws_route" "proj-jenk-Nat-association" {
  route_table_id            = aws_route_table.proj-jenk-private-route-table.id
  destination_cidr_block    = var.NAT-destin-cidr_block
  gateway_id                = aws_nat_gateway.proj-jenk-Nat-gateway.id
}
*/

/* Security Group resource with 2 ingress and 1 egress rules */
resource "aws_security_group" "proj-jenk-sec-group" {
  name        = var.secgroup-Name
  description = var.secgroup-Description
  vpc_id      = "${aws_vpc.proj-jenk.id}"


ingress {
    description      = var.ingress1-type
    from_port        = 22
    to_port          = 22
    protocol         = var.ingress1-protocol
    cidr_blocks      = var.ingress1-cidr_block
    ipv6_cidr_blocks = ["::/0"]
}

ingress {
    description      = var.ingress2-type
    from_port        = 80
    to_port          = 80
    protocol         = var.ingress2-protocol
    cidr_blocks      = var.ingress2-cidr_block
    ipv6_cidr_blocks = ["::/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = var.egress-protocol
    cidr_blocks      = var.egress-cidr_block
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = var.secgroup-Tag
  }
}

/* EC2 server in public subnet with Ubuntu Free Tier */
resource "aws_instance" "proj-jenk-serve-1" {
  ami           = var.proj-jenk-ami # eu-west-2, Ubuntu Free Tier
  instance_type = var.instance-type-name
  subnet_id     = "${aws_subnet.proj-jenk-public-sub1.id}"
  associate_public_ip_address = true

  credit_specification {
    cpu_credits = var.cpu-credit-specs 
  }

   tags = {
    Name = var.instance-Name
  }
}

/* EC2 server in private subnet with Ubuntu Free Tier */
resource "aws_instance" "proj-jenk-serve-2" {
  ami           = var.proj-jenk-ami # eu-west-2, Ubuntu Free Tier
  instance_type = var.instance-type-name
  vpc_security_group_ids = ["${aws_security_group.proj-jenk-sec-group.id}"]
  subnet_id     = "${aws_subnet.proj-jenk-private-sub2.id}"

  credit_specification {
    cpu_credits = var.private-cpu-specs 
  }
  
   tags = {
    Name = var.private-instance-Name
  }
}
