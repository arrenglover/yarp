// -*- mode:C++; tab-width:4; c-basic-offset:4; indent-tabs-mode:nil -*-

/*
 * Copyright (C) 2006 Paul Fitzpatrick
 * CopyPolicy: Released under the terms of the GNU GPL v2.0.
 *
 */

#ifndef _YARP2_INPUTSTREAM_
#define _YARP2_INPUTSTREAM_

#include <yarp/Bytes.h>

namespace yarp {
    namespace os {
        namespace impl {
            class InputStream;
        }
    }
}

/**
 * Simple specification of the minimum functions needed from input streams.
 * The streams could be TCP, UDP, MCAST, ...
 */
class yarp::os::impl::InputStream {
public:
    /**
     *
     * Constructor.
     *
     */
    InputStream() {
    }
  
    /**
     *
     * Destructor
     *
     */
    virtual ~InputStream() { }

    /**
     *
     * Perform maintenance actions, if needed.  This method is
     * called frequently by YARP when a stream is being accessed.
     * By default, it does nothing.
     *
     */
    virtual void check() {}

    /**
     *
     * Read and return a single byte.  Should block and wait for data.
     * By default, this calls read(const Bytes& b) to do its work.
     *
     * @return a byte from the stream (0-255), or -1 on failure.
     *
     */
    virtual int read() {
        unsigned char result;
        int ct = read(Bytes((char*)&result,1));
        if (ct<1) {
            return -1;
        }
        return result;
    }

    /**
     *
     * Read a block of data from the stream.  Should block and wait
     * for data. By default, this calls read(const Bytes& b) to do 
     * its work.
     *
     * @param b the block of data to read to
     * @param offset an offset within the block to start at
     * @param len the number of bytes to read
     *
     * @return the number of bytes read, or -1 upon error
     *
     */
    virtual int read(const Bytes& b, int offset, int len) { // throws
        return read(Bytes(b.get()+offset,len));
    }

    /**
     *
     * Read a block of data from the stream.  Should block and wait
     * for data.
     *
     * @param b the block of data to read to
     *
     * @return the number of bytes read, or -1 upon error
     *
     */
    virtual int read(const Bytes& b) = 0;

    /**
     *
     * Terminate the stream.
     *
     */
    virtual void close() = 0;

    /**
     *
     * Interrupt the stream.  If the stream is currently in
     * a blocked state, it must be unblocked.
     *
     */
    virtual void interrupt() {}

    /**
     *
     * Check if the stream is ok or in an error state.
     *
     * @return true iff the stream is ok
     *
     */
    virtual bool isOk() = 0;
};

#endif
