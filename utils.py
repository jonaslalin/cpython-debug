def pretty_print_header(heading: str, width=79, border="#") -> None:
    empty_space = width - len(heading) - 2
    pad_left = empty_space // 2
    pad_right = empty_space - pad_left
    print(border * width)
    print(f"{border}{pad_left * ' '}{heading}{pad_right * ' '}{border}")
    print(border * width)
