# Define our virtual private cloud
resource "aws_vpc" "lab" {
  cidr_block = "10.0.0.0/16"
}

# Define our subnets.
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
}
resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-2b"
}
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-2a"
}

# Define an internet gateway for the VPC. This doesn't, by itself, 
# grant internet access to the vpc; it just makes it possible by 
# being a target for routes.
resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
}

# Define a route table 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id

  # Direct all traffic through the gateway
  route {
    # This is a special CIDR block that represents 
    # "all IP addresses" or "everywhere on the internet."
    # The route cidr_block = "0.0.0.0/0" in a route table means 
    # "any traffic that is not specifically matched by another, 
    # more specific route should be sent to this target." 
    # It acts as a default route or a "catch-all."

    # Every route table automatically includes an implicit, 
    # non-editable route for the VPC's local CIDR block. 
    # In this case, this is 10.0.0.0/16. This route specifies 
    # that any traffic destined for an IP address within 10.0.0.0/16 
    # should be considered "local" and remain within the VPC.
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
}

# Asign route table to the public subnet
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a NAT gateway
# Allocate 
resource "aws_eip" "nat_gateway_eip" {
  vpc = true
}

resource "aws_nat_gateway" "lab" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public.id
  # Ensure the public subnet is properly associated with a route table
  # that has a route to an Internet Gateway.
  depends_on = [aws_internet_gateway.lab]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lab.id
}

# Add a route in the private route table for all outbound internet traffic (0.0.0.0/0)
# to go through the NAT Gateway.
resource "aws_route" "private_nat_gateway_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.lab.id
  depends_on             = [aws_nat_gateway.lab]
}

# Associate the Private Route Table with private network
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
