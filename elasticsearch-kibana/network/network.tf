resource "aws_vpc" "elastic_kibana_vpc" {
    cidr_block = "10.100.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "Elastic/Kibana VPC"
    }
}

resource "aws_internet_gateway" "elastic_kibana_gateway" {
    vpc_id = aws_vpc.elastic_kibana_vpc.id
    tags = {
        Name = "Elastic/Kibana Gateway"
    }
}

resource "aws_route" "public_access" {
    route_table_id = aws_vpc.elastic_kibana_vpc.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.elastic_kibana_gateway.id
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.elastic_kibana_vpc.id
    cidr_block = "10.100.1.0/24"
    map_public_ip_on_launch = true
    tags = {
        Name = "Public subnet for Kibana"
    }
}

resource "aws_eip" "nat_ip" {

}

resource "aws_nat_gateway" "elastic_kibana_nat" {
    allocation_id = aws_eip.nat_ip.id
    subnet_id = aws_subnet.public_subnet.id
} 

resource "aws_route_table" "elk_route" {
    vpc_id = aws_vpc.elastic_kibana_vpc.id
    tags = {
        Name = "Private route table"
    }
}

resource "aws_route" "private_access" {
    route_table_id = aws_route_table.elk_route.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.elastic_kibana_nat.id
}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.elastic_kibana_vpc.id
    cidr_block = "10.100.2.0/24"
    tags = {
        Name = "Private subnet for Elasticsearch"
    }
}

resource "aws_route_table_association" "public_subnet_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_vpc.elastic_kibana_vpc.main_route_table_id
}

resource "aws_route_table_association" "private_subnet_association" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.elk_route.id
}
