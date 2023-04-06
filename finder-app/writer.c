// hello

#include <stdlib.h>
#include <syslog.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

int main(int argc, char* argv[argc+1]) {

    openlog("writer", 0, LOG_USER);

    if (argc != 3) {
        printf("Usage: writer <filename> <string>\n");
        syslog(LOG_ERR, "Expecting 3 arguments but received %d", argc);
        closelog();
        return EXIT_FAILURE;
    }

    char* filename = argv[1];
    char* str = argv[2];

    int fd = open(filename, O_WRONLY | O_CREAT, 0660);

    if (fd == -1) {
        int errnum = errno;
        // fprintf(stderr, "Error opening file: %s\n", strerror( errnum ));
        syslog(LOG_ERR, "Error opening file: %s\n", strerror( errnum ));
        return EXIT_FAILURE;
    } else {
        syslog(LOG_INFO, "Writing %s to %s\n", str, filename);
        ssize_t result = write(fd, str, strlen(str));

        if (result == -1) {
            int errnum = errno;
            syslog(LOG_ERR, "Error writing to file: %s\n", strerror( errnum ));
            return EXIT_FAILURE;
        }
        close(fd);
    }


    closelog();
    return EXIT_SUCCESS;
}