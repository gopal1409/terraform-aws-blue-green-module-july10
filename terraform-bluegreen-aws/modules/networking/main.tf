##this is the vpc module defination
resource "aws_vpc" "this" {

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    var.tags,
    {
        Name = "${var.project}-${var.environment}-vpc"
    }
  )
}

##################public subnet
resource "aws_subnet" "public" {

  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.this.id #this will ensure that the subnet is created and attach to this vpc
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${each.key}"
   
  }
}
##lets create the private subnet
resource "aws_subnet" "private" {
  for_each                = var.private_subnets
  vpc_id                  = aws_vpc.this.id #this will ensure that the subnet is created and attach to this vpc
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${each.key}"
   
  }
}

###########internet gw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
        Name = "${var.project}-igw"
    }
  )
}
#route table public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
#association of RTB
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
