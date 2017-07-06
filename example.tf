# Configure Azure provider
provider "azure" {
  publish_settings = ${file("credentials.publishsettings")}

}

# Create web server
resource "azure_instance" "web" {

}
