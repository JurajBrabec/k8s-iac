type == "object" and
has("lab-server") and
(([keys[] | select(. != "lab-server")] | length) >= 1) and
(([keys[] | select(. != "lab-server")] | length) <= 3)
