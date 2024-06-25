#!/usr/bin/env bash

  echo "--------------------------------------------------------------------------------------------"
  echo "Same apps running on Cloud Foundry"
  echo "--------------------------------------------------------------------------------------------"
  cf app springj8 | grep "#0"
  cf app springj21 | grep "#0"
  cf app springnative | grep "#0"
