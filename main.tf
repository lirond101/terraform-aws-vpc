resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_subnet" "public_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  count                   = length(var.public_subnets)
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zone[count.index]
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  tags = merge(var.common_tags, var.public_subnet_tags, {
    Name = "${var.name_prefix}-public-${var.availability_zone[count.index]}",
    Tier = "Public"
  })
}

resource "aws_subnet" "private_subnet" {
  depends_on = [
    aws_vpc.vpc,
  ]

  count             = length(var.private_subnets)
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zone[count.index]
  vpc_id            = aws_vpc.vpc.id
  tags = merge(var.common_tags, var.private_subnet_tags, {
    Name = "${var.name_prefix}-private-${var.availability_zone[count.index]}",
    Tier = "Private"
  })
}

resource "aws_internet_gateway" "igw" {
  depends_on = [
    aws_vpc.vpc,
  ]

  vpc_id = aws_vpc.vpc.id
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

resource "aws_route_table" "IG_route_table" {
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.igw
  ]

  vpc_id = aws_vpc.vpc.id
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-IG-rt"
  })
}

resource "aws_route" "ngw-default-route" {
    depends_on = [
    aws_route_table.IG_route_table,
  ]

  route_table_id         = aws_route_table.IG_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "associate_routetable_to_public_subnet" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_route_table.IG_route_table,
  ]

  count          = length(var.public_subnets)
  route_table_id = aws_route_table.IG_route_table.id
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
}

resource "aws_eip" "elastic_ip" {
  count = length(var.public_subnets)
  vpc   = true
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-eip-${count.index+1}"
  })
}

resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [
    aws_subnet.public_subnet,
    aws_eip.elastic_ip,
  ]

  count         = length(var.public_subnets)
  allocation_id = aws_eip.elastic_ip.*.id[count.index]
  subnet_id     = aws_subnet.public_subnet.*.id[count.index]
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-nat-gateway-${count.index+1}"
  })
}

resource "aws_route_table" "NAT_route_table" {
  depends_on = [
    aws_vpc.vpc,
    aws_nat_gateway.nat_gateway,
  ]

  vpc_id = aws_vpc.vpc.id
  count  = length(var.public_subnets)
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-NAT-rt-${count.index+1}"
  })
}

resource "aws_route" "nat-default-route" {
  depends_on = [
    aws_route_table.NAT_route_table,
  ]

  count                  = length(var.public_subnets)
  route_table_id         = aws_route_table.NAT_route_table.*.id[count.index]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway.*.id[count.index]
}

resource "aws_route_table_association" "associate_routetable_to_private_subnet" {
  depends_on = [
    aws_subnet.private_subnet,
    aws_route_table.NAT_route_table,
  ]

  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.private_subnet.*.id[count.index]
  route_table_id = aws_route_table.NAT_route_table.*.id[count.index]
}

