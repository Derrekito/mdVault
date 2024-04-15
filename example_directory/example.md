---
id: example
author:
  - FirstName LastName
email: yourEmail@domain.com
secnum: false
title: "example"
toc: false
logo: true
rev: 0.1
bib: false
abstract: Some example abstract
date: 2024-10-28
---

# Example Introduction

Welcome to this document. Here you will find basic information about our project.

## Example Overview

This subsection provides an overview of the project's purpose and main features.

# Example Installation

Follow these steps to install the software:

```bash
sudo apt update
sudo apt install -y your-software
```

# Usage

To use the software, start by entering the following command:

```bash
your-software --help
```

## Subsection B: Advanced Usage

For more advanced features, use the options described below:

```bash
your-software --option1
your-software --option2
```

# Example Diagrams

## State Machine Diagram

Below is an example of a Mermaid diagram representing a simple state machine:

```mermaid{.mermaid width="50%"}
stateDiagram-v2
[*] --> OK

OK --> OK

OK --> BAD_REGISTER
BAD_REGISTER --> BAD_CACHE

BAD_REGISTER --> OK
BAD_CACHE --> BAD_DRAM
BAD_CACHE --> OK
BAD_DRAM --> OK
BAD_DRAM --> [*]
```

## Gantt Diagram

```mermaid
gantt
    title A Gantt Diagram
    dateFormat YYYY-MM-DD
    section Section
        A task          :a1, 2014-01-01, 30d
        Another task    :after a1, 20d
    section Another
        Task in Another :2014-01-12, 12d
        another task    :24d
```

# Conclusion

DONE
