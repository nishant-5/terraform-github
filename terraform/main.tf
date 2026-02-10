provider "aws" { 
    region = "us-east-1"
}

resource "aws_vpc" "main"{
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true 
    enable_dns_hostnames = true 
    instance_tenancy = "default"
    tags = {
        Name = "main"
    }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnets"{
    count = 4
    vpc_id = aws_vpc.main.id 
    availability_zone = data.aws_availability_zones.available.names[count.index]
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block,4,count.index)
    map_public_ip_on_launch = true
    tags = {
        Name = "public_subnets_${count.index + 1}"
    }
}

resource "aws_subnet" "private_subnets"{
    count = 2
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block,4,count.index+4)
    availability_zone = data.aws_availability_zones.available.names[count.index+2]
    vpc_id = aws_vpc.main.id 
    tags = { 
        Name = "private_subnets_${count.index + 1}"
    }
}

resource "aws_route_table" "public_route_table"{
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "public_route_table"
    }
}

resource "aws_route_table" "private_route_table"{
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "private_route_table"
    }
}

resource "aws_internet_gateway" "main_igw"{
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "main_igw"
    }
}

resource "aws_route" "public_route"{
    route_table_id = aws_route_table.public_route_table.id 
    gateway_id = aws_internet_gateway.main_igw.id 
    destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}


resource "aws_route_table_association" "public_association"{
    count = 4
    subnet_id = aws_subnet.public_subnets[count.index].id 
    route_table_id = aws_route_table.public_route_table.id 
}

resource "aws_route_table_association" "private_association"{
    count = 2
    subnet_id = aws_subnet.private_subnets[count.index].id 
    route_table_id = aws_route_table.private_route_table.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id  # Placing NAT GW in the first public subnet

  tags = {
    Name = "main-nat-gw"
  }

  depends_on = [aws_internet_gateway.main_igw]
}
