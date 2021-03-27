provider "aws" {
  region = "ap-south-1"
  profile = "aditya-ttn"
}

# vpc

resource "aws_vpc" "project_vpc" {
  cidr_block       = "192.168.0.0/16"

  tags = {
    Name = "project_vpc"
  }
}
#public subnet
resource "aws_subnet" "public_subnet-1a" {
  vpc_id     = aws_vpc.project_vpc.id
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone= "ap-south-1a"


  tags = {
    Name = "public_subnet-1a"
  }

}
#private subnet
resource "aws_subnet" "private_subnet-1b" {
  vpc_id     = aws_vpc.project_vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone= "ap-south-1b"
  
  tags = {
    Name = "private_subnet-1b"
  }
}
#internet gateway
resource "aws_internet_gateway" "ig-way" {
  vpc_id = aws_vpc.project_vpc.id


  tags = {
    Name = "main"
  }
depends_on = [
 aws_vpc.project_vpc
]
}
#route_table


resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.project_vpc.id
  depends_on = [aws_internet_gateway.ig-way ]


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig-way.id
  }
  tags = {
    Name = "route-table"
}
}


#route_table_association of public subnet with internet gateway


resource "aws_route_table_association" "associate" {
  subnet_id      = aws_subnet.public_subnet-1a.id
  route_table_id = aws_route_table.route-table.id
}

#eip for nat gateway

resource "aws_eip" "eip_for_NAT" {
  vpc = true
  }
#nat gateway creation 

resource "aws_nat_gateway" "NAT-gateway" {
  depends_on = [aws_internet_gateway.ig-way,aws_eip.eip_for_NAT]
  allocation_id = aws_eip.eip_for_NAT.id
  subnet_id     = aws_subnet.public_subnet-1a.id
  
  tags = {
    Name = "NAT-gateway"
  }
 }

#nat route table 

resource "aws_route_table" "route-nat" {
  depends_on = [aws_nat_gateway.NAT-gateway]
  vpc_id = aws_vpc.project_vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NAT-gateway.id
  }


  tags = {
    Name = "route-nat"
  }
}

#route_table_association of private subnet with NAT gateway
resource "aws_route_table_association" "nat-associate" {
  depends_on = [aws_route_table.route-nat]
  subnet_id      = aws_subnet.private_subnet-1b.id
  route_table_id = aws_route_table.route-nat.id
}




