variable "name" {
    default = "raghav"
}
#AWS specific part
variable "ami" {
  default = "ami-00068cd7555f543d5"
}

variable "region" {
  default = "us-east-1"
}

variable "availability_zones" {
  default = ["us-east-1a","us-east-1b"]
}
variable "instance_type_indexer" {
  default = "t2.micro"
}


#AWS Key_pair
variable "key_name" {
  default = "admin"
}
