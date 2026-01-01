using OceanAnalysis

oad(debug, a) = println(a)

"""
    read_sealevel(file::String; debug::Int64=0)

Read a sealevel File

This function starts by scanning the first line of the file, from which it
determines whether the file is in one of two known formats: type 1, the
format used at the Hawaii archive centre, and type 2, the
comma-separated-value format used by the Marine Environmental Data Service.
The file type is inferred by examination of its first line. If that contains
the string `Station_Name` the file is of type 2.

The Hawaii archive site at
`http://ilikai.soest.hawaii.edu/uhslc/datai.html` at one time provided a graphical
interface for downloading sealevel data in Type 1, with format that was once
described at `http://ilikai.soest.hawaii.edu/rqds/hourly.fmt` (although that link
was observed to no longer work, on December 4, 2016).
Examination of data retrieved from what seems to be a replacement Hawaii server
(https://uhslc.soest.hawaii.edu/data/?rq) in September 2019 indicated that the
format had been changed to what is called Type 3 by `read.sealevel`.
Web searches did not uncover documentation on this format, so the
decoding scheme was developed solely through examination of
data files, which means that it might be not be correct.
The [MEDS repository](http://www.isdm-gdsi.gc.ca/isdm-gdsi/index-eng.html)
provides Type 2 data.

# Arguments

- `file` String holding the name of the file to be read.

# Keywords

- `debug`: An integer controlling whether to print information during processing. The default is to work silently; use any positive value to get some printing.
"""
function read_sealevel(file::String; debug::Int64=0)
    oad(debug, "read_sealevel() START")
    !ismissing(file) || error("must supply 'file'")
    oad(debug, "END read_sealevel()")
end
read_sealevel("h275a.csv", debug=1)

#    firstLine <- readLines(file, n = 1)
#    header <- firstLine
#    oceDebug(debug, "header (first line in file): '", header, "'\n", sep = "")
#    pushBack(firstLine, file)
#    stationNumber <- NA
#    stationVersion <- NA
#    stationName <- NULL
#    region <- NULL
#    year <- NA
#    latitude <- NA
#    longitude <- NA
#    GMTOffset <- NA
#    decimationMethod <- NA
#    referenceOffset <- NA
#    referenceCode <- NA
#    res <- new("sealevel")
#    if (substr(firstLine, 1, 12) == "Station_Name") {
#        oceDebug(debug, "File is of format 1 (e.g. as in MEDS archives)\n")
#        # Station_Name,HALIFAX
#        # Station_Number,490
#        # Latitude_Decimal_Degrees,44.666667
#        # Longitude_Decimal_Degrees,63.583333
#        # Datum,CD
#        # Time_Zone,AST
#        # SLEV=Observed Water Level
#        # Obs_date,SLEV
#        # 01/01/2001 12:00 AM,1.82,
#        headerLength <- 8
#        header <- readLines(file, n = headerLength)
#        if (debug > 0) {
#            print(header)
#        }
#        stationName <- strsplit(header[1], ",")[[1]][2]
#        stationNumber <- as.numeric(strsplit(header[2], ",")[[1]][2])
#        latitude <- as.numeric(strsplit(header[3], ",")[[1]][2])
#        longitude <- as.numeric(strsplit(header[4], ",")[[1]][2])
#        tz <- strsplit(header[6], ",")[[1]][2] # needed for get GMT offset
#        GMTOffset <- GMTOffsetFromTz(tz)
#        oceDebug(debug, "about to read data\n")
#        x <- read.csv(file, header = FALSE, stringsAsFactors = FALSE, encoding = encoding)
#        oceDebug(debug, "... finished reading data\n")
#        if (length(grep("[0-9]{4}/", x$V1[1])) > 0) {
#            oceDebug(debug, "Date format is year/month/day hour:min with hour in range 1:24\n")
#            time <- strptime(as.character(x$V1), "%Y/%m/%d %H:%M", "UTC") + 3600 * GMTOffset
#        } else {
#            oceDebug(debug, "Date format is day/month/year hour:min AMPM with hour in range 1:12 and AMPM indicating whether day or night\n")
#            time <- strptime(as.character(x$V1), "%d/%m/%Y %I:%M %p", "UTC") + 3600 * GMTOffset
#        }
#        elevation <- as.numeric(x$V2)
#        oceDebug(
#            debug, "tz=", tz, "so GMTOffset=", GMTOffset, "\n",
#            "first pass has time string:", as.character(x$V1)[1], "\n",
#            "first pass has time start:", format(time[1]), " ", attr(time[1], "tzone"), "\n"
#        )
#        year <- as.POSIXlt(time[1])$year + 1900
#    } else {
#        oceDebug(debug, "File is of type 2 or 3\n")
#        d <- readLines(file)
#        n <- length(d)
#        header <- d[1]
#        if (grepl("LAT=", header) && grepl("LONG=", header) && grepl("TIMEZONE", header)) {
#            # URL
#            # http://uhslc.soest.hawaii.edu/woce/h275.dat
#            # is a sample file, which starts as below (with quote marks added):
#            # '275HALIFAX 1895  LAT=44 40.0N  LONG=063 35.0W  TIMEZONE=GMT '
#            # '275HALIFAX 189501011 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999'
#            # '275HALIFAX 189501012 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999'
#            oceDebug(debug, "type 3 (format inferred/guessed from e.g. http://uhslc.soest.hawaii.edu/woce/h275.dat)\n")
#            stationNumber <- strtrim(header, 3)
#            oceDebug(debug, "  stationNumber=\"", stationNumber, "\"\n", sep = "")
#            longitudeString <- gsub("^.*LONG=([ 0-9.]*[EWew]).*$", "\\1", header)
#            latitudeString <- gsub("^.*LAT=([ 0-9.]*[NSns]).*$", "\\1", header)
#            oceDebug(debug, "  longitudeString=\"", longitudeString, "\"\n", sep = "")
#            oceDebug(debug, "  latitudeString=\"", latitudeString, "\"\n", sep = "")
#            longitudeSplit <- strsplit(longitudeString, split = "[ \t]+")[[1]]
#            longitudeDegree <- longitudeSplit[1]
#            longitudeMinute <- longitudeSplit[2]
#            oceDebug(debug, "  longitudeDegree=\"", longitudeDegree, "\"\n", sep = "")
#            oceDebug(debug, "  longitudeMinute=\"", longitudeMinute, "\"\n", sep = "")
#            longitudeSign <- if (grepl("[wW]", longitudeMinute)) -1 else 1
#            oceDebug(debug, "  longitudeSign=", longitudeSign, "\n")
#            longitudeMinute <- gsub("[EWew]", "", longitudeMinute)
#            oceDebug(debug, "  longitudeMinute=\"", longitudeMinute, "\" after removing EW suffix\n", sep = "")
#            longitude <- longitudeSign * (as.numeric(longitudeDegree) + as.numeric(longitudeMinute) / 60)
#            oceDebug(debug, "  longitude=", longitude, "\n")
#            latitudeSplit <- strsplit(latitudeString, split = "[ \t]+")[[1]]
#            latitudeDegree <- latitudeSplit[1]
#            latitudeMinute <- latitudeSplit[2]
#            latitudeSign <- if (grepl("[sS]", latitudeMinute)) -1 else 1
#            oceDebug(debug, "  latitudeSign=", latitudeSign, "\n")
#            latitudeMinute <- gsub("[SNsn]", "", latitudeMinute)
#            oceDebug(debug, "  latitudeMinute=\"", latitudeMinute, "\" after removing NS suffix\n", sep = "")
#            latitude <- latitudeSign * (as.numeric(latitudeDegree) + as.numeric(latitudeMinute) / 60)
#            oceDebug(debug, "  latitude=", latitude, "\n")
#            # Remove interspersed year boundaries (which look like the first line).
#            d2 <- d[!grepl("LAT=.*LONG=", d)]
#            start <- 1 + which(strsplit(header, "")[[1]] == " ")[1]
#            d3 <- substr(d2, start, 1000L)
#            # Fix problem where the month is sometimes e.g. " 1" instead of "01"
#            d4 <- gsub("^([1-9][0-9]{3}) ", "\\10", d3)
#            # Fix problem where the day is sometimes e.g. " 1" instead of "01"
#            d5 <- gsub("^([1-9][0-9]{3}[0-9]{2}) ", "\\10", d4)
#            n <- length(d5)
#            # Now we have as below. But the second block sometimes has " " for "0", so we
#            # need to fix that.
#            # 275HALIFAX 189501011 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999
#            twelve <- seq(1, 12, 1)
#            elevation <- rep(NA, 12 * n)
#            time <- rep(NA, 12 * n)
#            lastDayPortion <- NULL # value defined at i=1, checked at i>2, so the initial value is immaterial
#            for (i in 1:n) {
#                sp <- strsplit(d5[i], "[ ]+")[[1]]
#                target.index <- 12 * (i - 1) + twelve
#                if (length(sp) != 13) {
#                    stop("cannot parse tokens on line \"", d2[i], "\"\n", sep = "")
#                }
#                elevation[target.index] <- as.numeric(sp[2:13])
#                dayPortion <- as.numeric(substr(sp[1], 9, 9))
#                if (i == 1) {
#                    startDay <- as.POSIXct(strptime(paste(substr(sp[1], 1, 8), "00:00:00"), "%Y%m%d"), tz = tz)
#                    oceDebug(debug, "  startDay=", startDay, "\n")
#                } else {
#                    if (dayPortion == 1) {
#                        if (i > 2 && lastDayPortion != 2) {
#                            stop("non-alternating day portions on data line ", i)
#                        }
#                    } else if (dayPortion == 2) {
#                        if (i > 2 && lastDayPortion != 1) {
#                            stop("non-alternating day portions on data line ", i)
#                        }
#                    } else {
#                        stop("day portion is ", dayPortion, " but must be 1 or 2, on data line", i)
#                    }
#                }
#                lastDayPortion <- dayPortion
#                time[target.index] <- as.POSIXct(sp[1], format = "%Y%m%d", tz = "UTC") + 3600 * (seq(0, 11) + 12 * (dayPortion - 1))
#            }
#            elevation[elevation == 9999] <- NA
#            elevation <- elevation / 1000 # convert mm to m
#            time <- numberAsPOSIXct(time, tz = "UTC") # guess on timezone
#        } else {
#            oceDebug(debug, "type 2 (an old Hawaii format, inferred from documentation)\n")
#            stationNumber <- substr(header, 1, 3)
#            stationVersion <- substr(header, 4, 4)
#            stationName <- substr(header, 6, 23)
#            stationName <- sub("[ ]*$", "", stationName)
#            region <- substr(header, 25, 43)
#            region <- sub("[ ]*$", "", region)
#            year <- substr(header, 45, 48)
#            latitudeStr <- substr(header, 50, 55) # degrees,minutes,tenths,hemisphere
#            latitude <- as.numeric(substr(latitudeStr, 1, 2)) + (as.numeric(substr(latitudeStr, 3, 5))) / 600
#            if (tolower(substr(latitudeStr, 6, 6)) == "s") latitude <- -latitude
#            longitudeStr <- substr(header, 57, 63) # degrees,minutes,tenths,hemisphere
#            longitude <- as.numeric(substr(longitudeStr, 1, 3)) + (as.numeric(substr(longitudeStr, 4, 6))) / 600
#            if (tolower(substr(longitudeStr, 7, 7)) == "w") longitude <- -longitude
#            GMTOffset <- substr(header, 65, 68) # hours,tenths (East is +ve)
#            oceDebug(debug, "GMTOffset=", GMTOffset, "\n")
#            decimationMethod <- substr(header, 70, 70) # 1=filtered 2=average 3=spot readings 4=other
#            referenceOffset <- substr(header, 72, 76) # add to values
#            referenceCode <- substr(header, 77, 77) # add to values
#            units <- substr(header, 79, 80)
#            oceDebug(debug, "units=", units, "\n")
#            if (nchar(units) == 0) {
#                warning("no units can be inferred from the file, so assuming \"mm\"")
#            } else {
#                if (units != "mm" && units != "MM") {
#                    stop("require units to be \"mm\" or \"MM\", not \"", units, "\"")
#                }
#            }
#            elevation <- array(NA_real_, 12 * (n - 1))
#            twelve <- seq(1, 12, 1)
#            lastDayPortion <- -1 # ignored; prevents undefined warning in code analysis
#            for (i in 2:n) {
#                sp <- strsplit(d[i], "[ ]+")[[1]]
#                target.index <- 12 * (i - 2) + twelve
#                elevation[target.index] <- as.numeric(sp[4:15])
#                dayPortion <- as.numeric(substr(sp[3], 9, 9))
#                if (i == 2) {
#                    startDay <- as.POSIXct(strptime(paste(substr(sp[3], 1, 8), "00:00:00"), "%Y%m%d"), tz = tz)
#                } else {
#                    if (dayPortion == 1) {
#                        if (i > 2 && lastDayPortion != 2) {
#                            stop("non-alternating day portions on data line ", i)
#                        }
#                    } else if (dayPortion == 2) {
#                        if (i > 2 && lastDayPortion != 1) {
#                            stop("non-alternating day portions on data line ", i)
#                        }
#                    } else {
#                        stop("day portion is ", dayPortion, " but must be 1 or 2, on data line", i)
#                    }
#                }
#                lastDayPortion <- dayPortion
#            }
#            time <- as.POSIXct(startDay + 3600 * (seq(0, 12 * (n - 1) - 1)), tz = tz)
#            elevation[elevation == 9999] <- NA
#            if (tolower(units) == "mm") {
#                elevation <- elevation / 1000
#            } else {
#                stop("require units to be MM")
#            }
#        }
#    }
#    res@metadata$filename <- filename
#    res@metadata$header <- header
#    res@metadata$year <- year
#    res@metadata$stationNumber <- stationNumber
#    res@metadata$stationVersion <- stationVersion
#    res@metadata$stationName <- stationName
#    res@metadata$region <- region
#    res@metadata$latitude <- latitude
#    res@metadata$longitude <- longitude
#    res@metadata$GMTOffset <- GMTOffset
#    res@metadata$decimationMethod <- decimationMethod
#    res@metadata$referenceOffset <- referenceOffset
#    res@metadata$referenceCode <- referenceCode
#    res@metadata$units <- list(elevation = list(unit = expression(m), scale = ""))
#    res@metadata$n <- length(time)
#    # deltat is in hours
#    res@metadata$deltat <- if (res@metadata$n > 1) (as.numeric(time[2]) - as.numeric(time[1])) / 3600 else 0
#    res@data$elevation <- elevation
#    res@data$time <- time
#    res@processingLog <- processingLogAppend(
#        res@processingLog,
#        paste("read.sealevel(file=\"", filename, "\", tz=\"", tz, "\")", sep = "", collapse = "")
#    )
#    oceDebug(debug, "END read.sealevel()\n", unindent = 1)
#    res
#}
