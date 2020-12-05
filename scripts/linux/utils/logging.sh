#!/bin/bash

function log_notify() { log 0 "[NOTE]: $1"; }
function log_critical() { log 1 "CRITICAL: $1"; }
function log_error() { log 2 "[ERROR]: $1"; }
function log_warn() { log 3 "[WARNING]: $1"; }
function log_inf() { log 4 "[INFO]: $1"; } 
function log_debug() { log 5 "[DEBUG]: $1"; }

function log() {

    datestring=$(date +'%Y-%m-%d %H:%M:%S')
    # Expand escaped characters, wrap at 70 chars, indent wrapped lines
    echo -e "$datestring $2" | fold -w70 -s | sed '2~1s/^/  /' 

}
