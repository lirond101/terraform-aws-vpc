resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = var.common_tags
}

resource "aws_subnet" "public_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  count                   = 2
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zone[count.index]
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags = {
    Name = "public-subnet-${count.index+1}"
  }
}

resource "aws_subnet" "private_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  count             = 2
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zone[count.index]
  vpc_id            = aws_vpc.vpc.id
  tags = {
    Name = "private-subnet-${count.index+1}"
  }
}

resource "aws_internet_gateway" "igw" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.naming_prefix}-igw"
  }
}

resource "aws_route_table" "IG_route_table" {
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.igw
  ]

  vpc_id = aws_vpc.vpc.id
  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_internet_gateway.igw.id
  # }
  tags = {
    Name = "${var.naming_prefix}-IG-rt"
  }
}

resource "aws_route" "ngw-default-route" {
    depends_on = [
    aws_route_table.IG_route_table,
  ]
  route_table_id         = aws_route_table.IG_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# associate route table to public subnet
resource "aws_route_table_association" "associate_routetable_to_public_subnet" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_route_table.IG_route_table,
  ]

  count          = 2
  route_table_id = aws_route_table.IG_route_table.id
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
}

# elastic ip
resource "aws_eip" "elastic_ip" {
  count = 2
  vpc   = true

  tags = {
    Name = "${var.naming_prefix}-eip-${count.index+1}"
  }
}

# NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_eip.elastic_ip,
  ]

  count         = 2
  allocation_id = aws_eip.elastic_ip.*.id[count.index]
  subnet_id     = aws_subnet.public_subnet.*.id[count.index]

  tags = {
    Name = "${var.naming_prefix}-nat-gateway-${count.index+1}"
  }
}

# route table with target as NAT gateway
resource "aws_route_table" "NAT_route_table" {
  depends_on = [
    aws_vpc.vpc,
    aws_nat_gateway.nat_gateway,
  ]

  vpc_id = aws_vpc.vpc.id
  count  = 2
  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_nat_gateway.nat_gateway.*.id[count.index]
  # }

  tags = {
    Name = "${var.naming_prefix}-NAT-rt-${count.index+1}"
  }
}

resource "aws_route" "nat-default-route" {
  depends_on = [
    aws_route_table.NAT_route_table,
  ]
  count  = 2
  route_table_id         = aws_route_table.NAT_route_table.*.id[count.index]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway.*.id[count.index]
}

# associate route table to private subnet
resource "aws_route_table_association" "associate_routetable_to_private_subnet" {
  depends_on = [
    aws_subnet.private_subnet,
    aws_route_table.NAT_route_table,
  ]

  count          = 2
  subnet_id      = aws_subnet.private_subnet.*.id[count.index]
  route_table_id = aws_route_table.NAT_route_table.*.id[count.index]
}

