variable "key_name" {
  description = "The name of the key pair"
  type        = string
  default     = "eden-key-v2"
}
variable "private_key_filename" {
  description = "Filename for the private key to save locally"
  type        = string
  default     = "eden-key-v2"
}