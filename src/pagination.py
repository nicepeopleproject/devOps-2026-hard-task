def paginate(items, page=1, per_page=10):
    start = (page - 1) * per_page
    end = start + per_page
    total = len(items)
    return {
        "items": items[start:end],
        "page": page,
        "per_page": per_page,
        "total": total,
        "pages": (total + per_page - 1) // per_page
    }
