
#' Import MSF data from a remote location
#'
#' @param path_local path_local
#' @param file_name file_name
#' @param path_remote path_remote
#' @param force force download
#'
#' @return
#' @export
#'
get_msf_linelist <- function(path_local = path.local.msf.data, file_name = 'dta_MSF_linelist.RDS', path_remote = path.sharepoint.data, force = FALSE) {

  dta_path_local  <- file.path(path_local, file_name)
  dta_path_remote <- max(fs::dir_ls(path_remote, regexp = "[.]rds$"))

  if (!file.exists(dta_path_local) || force) {

    dta <- readRDS(dta_path_remote)
    saveRDS(dta, file = dta_path_local)

  } else {

    dta <- readRDS(dta_path_local)

  }

  return(dta)
}
