#' Get occurrence data
#' 
#' Retrieve SBDI occurrence data via the "occurrence download" web service. At 
#' least one of \code{taxon}, \code{wkt}, or \code{fq} must be supplied for a 
#' valid query. 
# Note that there is a limit of 500000 records per request when 
# using \code{method="indexed"}. Use the \code{method="offline"} for larger 
# requests. For small requests, \code{method="indexed"} likely to be faster.
#' 
#' @references \itemize{
#' \item Associated SBDI web service for record counts: \url{https://api.bioatlas.se/#ws3}
#' \item Associated SBDI web service for occurence downloads: \url{https://api.bioatlas.se/#ws4}
#' \item Field definitions: \url{https://docs.google.com/spreadsheet/ccc?key=0AjNtzhUIIHeNdHhtcFVSM09qZ3c3N3ItUnBBc09TbHc}
#' \item WKT reference: \url{https://www.geoapi.org/3.0/javadoc/org/opengis/referencing/doc-files/WKT.html}
#' }
#' @param taxon string: (optional) query of the form field:value (e.g. "genus:Macropus")
#'  or a free text search (e.g. "macropodidae"). Note that a free-text search is 
#'  equivalent to specifying the "text" field (i.e. \code{taxon="Alaba"} is equivalent 
#'  to \code{taxon="text:Alaba"}. The text field is populated with the taxon name 
#'  along with a handful of other commonly-used fields, and so just specifying your
#'  target taxon (e.g. taxon="Alaba vibex") will probably work. However, for reliable 
#'  results it is recommended to use a specific field where possible (see 
#'  \code{sbdi_fields("occurrence_indexed")} for valid fields). It is also good 
#'  practice to quote the taxon name if it contains multiple words, for example
#' \code{taxon="taxon_name:\"Alaba vibex\""}
#' @param wkt string: (optional) a WKT (well-known text) string providing a spatial 
#' polygon within which to search, e.g. "POLYGON((140 -37,151 -37,151 -26,140.131 -26,140 -37))"
#' @param fq string: (optional) character string or vector of strings, specifying 
#' filters to be applied to the original query. These are of the form 
#' "INDEXEDFIELD:VALUE" e.g. "kingdom:Fungi". See \code{sbdi_fields("occurrence_indexed", as_is=TRUE)} 
#' for all the fields that are queryable. 
#' NOTE that fq matches are case-sensitive, but sometimes the entries in the fields are 
#' not consistent in terms of case (e.g. kingdom names "Fungi" and "Plantae" but "ANIMALIA"). 
#' fq matches are ANDed by default (e.g. c("field1:abc","field2:def") will match records that have 
#' field1 value "abc" and field2 value "def"). To obtain OR behavior, use the form c("field1:abc 
#' OR field2:def"). See e.g. \url{https://wiki.apache.org/solr/CommonQueryParameters} 
#' for more information about filter queries
#' @param fields string vector: (optional) a vector of field names to return. 
#' Note that the columns of the returned data frame are not guaranteed to retain
#'  the ordering of the field names given here. If not specified, a default list 
#'  of fields will be returned. See \code{sbdi_fields("occurrence_stored")}. 
#'  Field names can be passed as full names (e.g. "Radiation - lowest period 
#'  (Bio22)") rather than id ("el871"). Use \code{fields="all"} to include all 
#'  available fields.
#' @param extra string vector: (optional) a vector of field names to include in 
#' addition to those specified in \code{fields}. This is useful if you would like 
#' the default list of fields (i.e. when \code{fields} parameter is not specified) 
#' plus some additional extras. See \code{sbdi_fields("occurrence_stored",as_is=TRUE)} 
#' for valid field names. Field names can be passed as full names (e.g. "Radiation
#'  - lowest period (Bio22)") rather than id ("el871"). Use \code{extra="all"} 
#'  to include all available fields.
#' @param qa string vector: (optional) list of record issues to include in the 
#' download. Use \code{qa="all"} to include all available issues, or \code{qa="none"} 
#' to include none. Otherwise see \code{sbdi_fields("assertions",as_is=TRUE)} for
#' valid values
#' @param method [Deprecated]
#' @param email (required) string: the email address of the user performing the 
#' download  [default is set by sbdi_config()]
#' @param download_reason_id numeric or string: (required unless record_count_only is TRUE) 
#' a reason code for the download, either as a numeric ID (currently 0--11) or a 
#' string (see \code{\link{sbdi_reasons}} for a list of valid ID codes and names). 
#' The download_reason_id can be passed directly to this function, or alternatively
#' set using \code{sbdi_config(download_reason_id=...)}
#' @param reason string: (optional) user-supplied description of the reason for the 
#' download. Providing this information is optional but will help the SBDI to better 
#' support users by building a better understanding of user communities and their
#' data requests
#' @param verbose logical: show additional progress information? 
#' [default is set by sbdi_config()]
#' @param record_count_only logical: if TRUE, return just the count of records 
#' that would be downloaded, but don't download them. Note that the record count
#'  is always re-retrieved from the SBDI, regardless of the caching settings. If
#'  a cached copy of this query exists on the local machine, the actual data set 
#'  size may therefore differ from this record count. 
#' @param use_layer_names logical: if TRUE, layer names will be used as layer 
#' column names in the returned data frame (e.g. "watsonianViceCounties"). Otherwise, 
#' layer id value will be used for layer column names (e.g. "cl10009")
#' @param use_data_table logical: if TRUE, attempt to read the data.csv file using 
#' the fread function from the data.table package. Requires data.table to be available. 
#' If this fails with an error or warning, or if use_data_table is FALSE, then 
#' read.table will be used (which may be slower)
#' 
#' @return Data frame of occurrence results, with one row per occurrence record. 
#' The columns of the dataframe will depend on the requested fields
#' @seealso \code{\link{sbdi_reasons}} for download reasons; \code{\link{sbdi_config}}
#' @examples
#' \dontrun{
#' x <- occurrences(taxon="genus:Accipiter", 
#'                  fields=c("species","longitude","latitude","common_name","rank","rights"), 
#'                  download_reason_id=10)
#'  
#' ## download records in polygon, with no quality assertion information
#' mellan_sve <- "POLYGON((16.551 60.760,18.836 59.801,17.606 58.860,16.199 58.540,
#'                        12.244 58.494,12.772 61.523,16.551 60.760))"
#' x <- occurrences(taxon="genus:Accipiter",
#'                  wkt=mellan_sve, 
#'                  download_reason_id=10, 
#'                  qa="none", verbose = TRUE)
#' 
#' y <- occurrences(taxon="taxon_name:%22Accipiter gentilis%22",
#'                  wkt=mellan_sve, 
#'                  fields=c("latitude","longitude", "family", "collector", "rights"),
#'                  download_reason_id=10)
#' str(y)
#'
#' ## other filtered searches
#' 
#' fq_str<-pick_filter("resource")
#' 
#' z <- occurrences(taxon="genus:Accipiter",
#'                  fields=c("latitude","longitude","rights"),
#'                  wkt=mellan_sve, 
#'                  fq=fq_str, # e.g. c( "institution_uid:in3", "cl10097:Uppsala"),
#'                  #fq=c( "collection_uid:co3"), ## Artportalen data collection
#'                  #fq=c( "data_resource_uid:dr5"), ## Artportalen data resource
#'                  qa="none", download_reason_id=10)
#'                  
#' occurrence_plot(z)
#'                
#' }
#' @importFrom assertthat assert_that is.flag is.string
#' @export occurrences

occurrences <- function(taxon, wkt, fq, fields, extra, qa, 
                        email = sbdi_config()$email, 
                        method,
                        download_reason_id = sbdi_config()$download_reason_id,
                        reason,
                        verbose = sbdi_config()$verbose, 
                        record_count_only = FALSE,
                        use_layer_names = TRUE, 
                        use_data_table = TRUE) {
  
  assert_that(is.flag(record_count_only))
  
  # if (!missing(method)) {
  #   warning("Method is a deprecated field. All queries use offline method,
  #               unless record_count_only == TRUE, when indexed method is used")
  # }

  # if (missing(email) || !is.notempty.string(email)) {
  assert_that(is.notempty.string(email), msg = "email is required")

  
  #### FROM HERE the origial function
  ## check input parms are sensible
  assert_that(is.flag(record_count_only))
  if (record_count_only) {
    valid_fields_type <- "occurrence_stored"
  }
  else {
    valid_fields_type <- "occurrence"
  }
  this_query <- list()
  ## have we specified a taxon?
  if (!missing(taxon)) {
    if (is.factor(taxon)) {
      taxon <- as.character(taxon)
    }
    assert_that(is.notempty.string(taxon))
    this_query$q <- taxon
  }
  ## wkt string
  if (!missing(wkt)) {
    assert_that(is.notempty.string(wkt))
    this_query$wkt <- wkt
  }
  if (!missing(fq)) {
    assert_that(is.character(fq))
    ## can have multiple fq parameters, need to specify in url as
    ## fq=a:b&fq=c:d&fq=...
    check_fq(fq,type="occurrence") ## check that fq fields are valid
    fq <- as.list(fq)
    names(fq) <- rep("fq",length(fq))
    this_query <- c(this_query,fq)
  }
  if (length(this_query)==0) {
    ## not a valid request!
    stop("invalid request: need at least one of taxon, fq, or wkt to
             be specified")
  }
  
  ## check the number of records
  if (record_count_only) {
    ## check using e.g. https://biocache-ws.ala.org.au/ws/occurrences/se
    ## arch?q=*:*&pageSize=0&facet=off
    temp_query <- this_query
    temp_query$pageSize <- 0
    temp_query$facet <- "off"
    this_url <- build_url_from_parts(
      getOption("ALA4R_server_config")$base_url_biocache,
      c("occurrences","search"), query = temp_query)
    return(cached_get(url=this_url,type="json",caching="off",
                      verbose=verbose)$totalRecords)
  } else {
    # if (missing(email) || !is.string(email) || nchar(email)<1) {
    if (!is.string(email) || nchar(email)<1) {
      stop("email is required!")
    }
    this_query$email <- email
  }
  assert_that(is.flag(use_data_table))
  assert_that(is.flag(use_layer_names))
  reason_ok <- !is.na(download_reason_id)
  if (reason_ok) {
    valid_reasons <- sbdi_reasons()
    ## convert from string to numeric if needed
    download_reason_id <- convert_reason(download_reason_id)
    reason_ok <- download_reason_id %in% valid_reasons$id
  }
  if (! reason_ok) {
    stop("download_reason_id must be a valid reason_id. See ",
         getOption("ALA4R_server_config")$reasons_function,"()")
  }
  if (!missing(fields)) {
    assert_that(is.character(fields))
    ## user has specified some fields
    valid_fields <- sbdi_fields(fields_type=valid_fields_type,as_is=TRUE)
    if (identical(tolower(fields),"all")) fields <- valid_fields$name
    # # replace long names with ids
    fields <- fields_name_to_id(fields=fields,fields_type="occurrence")
    unknown <- setdiff(fields,valid_fields$name)
    if (length(unknown)>0) {
      stop("invalid fields requested: ", str_c(unknown,collapse=", "),
           ". See ",getOption("ALA4R_server_config")$fields_function,
           "(\"",valid_fields_type,"\",as_is=TRUE)")
    }
    this_query$fields <- str_c(fields,collapse=",")
  }
  if (!missing(extra)) {
    assert_that(is.character(extra))
    valid_fields <- sbdi_fields(fields_type = valid_fields_type, as_is=TRUE)
    if (identical(tolower(extra),"all")) extra <- valid_fields$name
    ## replace long names with ids
    extra <- fields_name_to_id(fields=extra, fields_type = "occurrence") 
    unknown <- setdiff(extra,valid_fields$name)
    if (length(unknown)>0) {
      stop("invalid extra fields requested: ",
           str_c(unknown,collapse=", "),
           ". See ",getOption("ALA4R_server_config")$fields_function,
           "(\"",valid_fields_type,"\",as_is=TRUE)")
    }
    this_query$extra <- str_c(extra,collapse=",")
  }
  if (!missing(qa)) {
    assert_that(is.character(qa))
    if (identical(tolower(qa),"all")) { qa <- sbdi_fields("assertions",
                                                         as_is=TRUE)$name }
    ## valid entries for qa
    valid_fields <- c("none",sbdi_fields(fields_type="assertions",
                                        as_is=TRUE)$name) 
    unknown <- setdiff(qa,valid_fields)
    if (length(unknown)>0) {
      stop("invalid qa fields requested: ", str_c(unknown,collapse=", "),
           ". See ",getOption("ALA4R_server_config")$fields_function,
           "(\"assertions\",as_is=TRUE)")
    }
    this_query$qa <- str_c(qa,collapse=",")
  }
  if (!missing(reason)) {
    assert_that(is.string(reason))
    this_query$reason <- reason
  }
  
  this_query$reasonTypeId <- download_reason_id
  
  if (getOption("ALA4R_server_config")$biocache_version > "1.8.1") {
    ## only for more recent biocache versions
    this_query$sourceTypeId <- sbdi_sourcetypeid() 
  }
  ## force backslash-escaping of quotes rather than double-quote escaping
  this_query$esc <- "\\" 
  this_query$sep <- "\t" ## tab-delimited
  ## to ensure that file is named "data.csv" within the zip file
  this_query$file <- "data"
  ## possibly use this to be more consistent with field names
  ##this_query$dwcHeaders <- "true" 
  
  this_url <- build_url_from_parts(
    getOption("ALA4R_server_config")$base_url_biocache,
    c("occurrences","offline","download"),query=this_query)
  
  ## the file that will ultimately hold the results (even if we are not
  ## caching, it still gets saved to file)
  thisfile <- sbdi_cache_filename(this_url)

  if ((sbdi_config()$caching %in% c("off","refresh")) ||
      (! file.exists(thisfile))) {
    status <- cached_get(url=this_url,caching="off",type="json",
                         verbose=verbose)
    if (!"statusUrl" %in% names(status)) {
      stop("reply from server was missing statusUrl. ",
           getOption("ALA4R_server_config")$notify)
    }
    this_status_url <- status$statusUrl
    status <- cached_get(this_status_url, 
                         caching="off",
                         type="json",
                         verbose=verbose)
    while (tolower(status$status) %in% c("inqueue","running")) {
      status <- cached_get(this_status_url, 
                           caching="off", 
                           type="json",
                           verbose=verbose)
      Sys.sleep(2)
    }
    ## May 2018: workaround for server-side bug
    ## see https://github.com/AtlasOfLivingAustralia/biocache-service/issue
    ## s/221#issuecomment-389740284
    if (tolower(status$status) %in% c("invalidid")) {
      tryCatch({
        ## pull out the uuid from the status URL
        this_uuid <- stringr::str_match(this_status_url,
                                        "status/([^/]+)/?$")[1, 2]
        ## change last "-" to "/"
        temp <- strsplit(this_uuid, "-")[[1]]
        temp <- paste0(paste(temp[-length(temp)], collapse="-"), "/",
                       temp[length(temp)])
        url_to_try <- build_url_from_parts(
          getOption("ALA4R_server_config")$
            base_url_biocache_download, c(temp, "data.zip"))
        download_to_file(url_to_try, outfile=thisfile,
                         binary_file=TRUE, verbose=verbose)
        status$status <- "finished" ## act as if it all worked!
      }, error=function(e) {
        stop("Offline download failed. ",
             getOption("ALA4R_server_config")$notify)
      })
    } else {
      if (status$status!="finished") {
        stop("unexpected response from server. ",
             getOption("ALA4R_server_config")$notify,
             ". The server response was: ", status$status)
      } else {
        ## finally we have the URL to the data file itself
        download_to_file(status$downloadUrl, outfile=thisfile,
                         binary_file=TRUE, verbose=verbose)
      }
    }
  } else {
    ## we are using the existing cached file
    if (verbose) message(sprintf("Using cached file %s for %s",
                                 thisfile, this_url))
  }
  ## these downloads can potentially be large, so we want to download
  ## directly to file and then read the file
  if (!(file.info(thisfile)$size>0)) {
    ## empty file
    x <- NULL
    ## actually this isn't a sufficient check, since even with empty
    ## data.csv file inside, the outer zip file will be > 0 bytes.
    ## Check again below on the actual data.csv file
  } else {
    read_ok <- FALSE
    if (use_data_table) {
      tryCatch({
        ## first need to extract data.csv from the zip file
        ## this may end up making fread() slower than direct
        ## read.table() ... needs testing
        tempsubdir <- tempfile(pattern="dir")
        if (verbose) {
          message(sprintf("Unzipping downloaded occurrences data.csv
                                    file into %s",tempsubdir))
        }
        dir.create(tempsubdir)
        unzip(thisfile, files=c("data.csv"), junkpaths=TRUE,
              exdir=tempsubdir)
        ## first check if file is empty
        if (file.info(file.path(tempsubdir,"data.csv"))$size>1) {
          x <- data.table::fread(file.path(tempsubdir, "data.csv"),
                                 data.table=FALSE,
                                 stringsAsFactors=FALSE, header=TRUE,
                                 verbose=verbose, sep="\t",
                                 na.strings="NA", logical01=FALSE, 
                                 encoding = sbdi_config()$text_encoding)
          names(x) <- make.names(names(x))
          if (!empty(x)) {
            ## convert column data types
            ## ALA supplies *all* values as quoted text, even
            ## numeric, and they appear here as character type
            ## we will convert whatever looks like numeric or
            ## logical to those classes
            for (cl in seq_len(ncol(x))) {
              x[, cl] <- convert_dt(x[, cl])
            }
          }
          read_ok <- TRUE
        } else {
          x <- data.frame() ## empty result set
          read_ok <- TRUE
        }
      }, warning=function(e) {
        if (verbose) {
          warning(paste("Reading of csv as data.table failed, will fall
                         back to read.table (may be slow). The warning
                         message was: ", e))
        }
        read_ok <- FALSE
      }
      , error=function(e) {
        if (verbose) {
          warning(paste("Reading of csv as data.table failed, will fall 
                         back to read.table (may be slow). The error message
                         was: ", e))
        }
        read_ok <- FALSE
      })
    }
    if (!read_ok) {
      
      x <- read.table(unz(thisfile, filename="data.csv"), header=TRUE,
                      comment.char="", as.is=TRUE, 
                      encoding = sbdi_config()$text_encoding)
      if (!empty(x)) {
        ## convert column data types
        ## read.table handles quoted numerics but not quoted logicals
        for (cl in seq_len(ncol(x))) {
          x[, cl] <- convert_dt(x[, cl], test_numeric=FALSE)
        }
      }
    }
    
    if (!empty(x)) {
      ## change e.g. el.xxx to elxxx
      names(x) <- str_replace_all(names(x),
                                  "^(el|cl)\\.([0-9]+)","\\1\\2") 
      ## TODO what is "cl.1050.b" etc?
      if (use_layer_names) {
        names(x) <- make.names(fields_id_to_name(names(x),
                                                 fields_type="layers"))
      } else {
        ## use make_names because names here have dots instead of
        ## spaces (not tested)
        names(x) <- make.names(fields_name_to_id(names(x),
                                                 fields_type="layers",
                                                 make_names=TRUE)) 
      }
      names(x) <- rename_variables(names(x),type="assertions")
      names(x) <- rename_variables(names(x),type="occurrence")
      ## remove unwanted columns
      xcols <- setdiff(names(x), unwanted_columns("occurrence"))
      x <- subset(x,select=xcols)
      ## also read the citation info
      ## this file won't exist if there are no rows in the data.csv file,
      ## so only do it if nrow(x)>0
      ## also wrap it in a try(...), so that it won't cause the function
      ## to fail if the citation.csv file isn't present
      xc <- "No citation information was returned, try again later"
      found_citation <- FALSE
      try({
        suppressWarnings(xc <- read.table(unz(thisfile,"citation.csv"),
                                          header=TRUE, comment.char="",
                                          as.is=TRUE, 
                                          encoding = sbdi_config()$text_encoding))
        found_citation <- TRUE},
        silent=TRUE)
      if (!found_citation) {
        ## as of around July 2016 the citation.csv file appears to have
        ## been replaced by README.html
        try({
          suppressWarnings(xc <- scan(unz(thisfile,"README.html"),
                                      what="character",sep="$",
                                      quiet=TRUE, 
                                      encoding = sbdi_config()$text_encoding))
          xc <- data.frame(citation=paste(xc,collapse=""))
          found_citation <- TRUE},
          silent=TRUE)
      }
      if (!found_citation & nrow(x)>0) {
        warning("citation file not found within downloaded zip file")
      }
    } else {
      if (sbdi_config()$warn_on_empty) {
        warning("no matching records were returned")
      }
      if (!missing(wkt) && !isTRUE(check_wkt(wkt))) {
        warning(paste("WKT string may not be valid: ", wkt))
      }
      xc <- NULL
    }
    x <- list(data=x,meta=xc)
  }
  class(x) <- c('occurrences',class(x)) #add the occurrences class
  x
    
  }
  