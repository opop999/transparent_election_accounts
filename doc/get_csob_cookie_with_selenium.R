get_csob_cookie <- function(host_port, container_port, adress) {
  
# Loading the required R libraries
  
  # Package names
  packages <- c("RSelenium", "data.table")
  
  # Install packages not yet installed
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)) {
    install.packages(packages[!installed_packages])
  }
  
  # Packages loading
  invisible(lapply(packages, library, character.only = TRUE))
  
# Pull the necessary Docker image
system("docker pull selenium/standalone-firefox")

Sys.sleep(5)

# Start the Docker container
system(paste0("docker run --rm -d --name selenium_headless -p ", host_port, ":", container_port," selenium/standalone-firefox"), wait = FALSE)
 
Sys.sleep(5)

# Connect to a Docker instance of headless Firefox server
remDr <- remoteDriver(
  remoteServerAddr = adress,
  port = host_port,
  browserName = "firefox"
)

Sys.sleep(5)

# Request to the server to instantiate browser
remDr$open()

# Request to selected url (can be any CSOB page, robots.txt is the most lightweight)
remDr$navigate("https://www.csob.cz/portal/robots.txt")

# Wait before page fully loaded
Sys.sleep(2)

# Save all of the cookies to an object-list
cookies_list <- remDr$getAllCookies()

# Merge the list to a dataframe
cookies_df <-  rbindlist(cookies_list, fill = TRUE)

# Subset the dataframe and set the cookie as an environmental variable
cookie = cookies_df[name == "TSPD_101", value]

# Delete the session & close open browsers.
remDr$quit()

# Stop the Docker container
system("docker stop selenium_headless")

return(cookie)

}

adress <- "localhost"
host_port <- 4445L
container_port <- 4444

# Run the function
get_csob_cookie(host_port = host_port, container_port = container_port, adress = adress)


