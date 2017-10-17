#' Calculate 1+1 and print out
#' 
#' With this script we calculate the sum of 1 and 1 and print it out
#' to the command line. We print it out as integer and as 2-digit
#' float.
#'
#' Just different comments in the code

# calculate 1+1
result = 1+1

# print the result out as integer
print(formatC(result, format='d'))

# print the result out as integer
print(formatC(result, format='f', width=4, digits=2))

#' Again a comment like in the beginning