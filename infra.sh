#!/bin/bash

go env -w GOPRIVATE=github.com/nctu-ucr/*
git config --global url."git@github.com:nctu-ucr/".insteadOf https://github.com/nctu-ucr/
