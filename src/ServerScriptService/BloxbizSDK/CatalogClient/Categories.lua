export type Subcategory = {
	name: string,
	query: {
		AssetTypeId: number?,
		Category: number?,
		Subcategory: number?,
	},
	default_sort: number?,
}

export type Category = {
	name: string,
	subcategories: { Subcategory },
	is_ad: boolean,
}

local Categories = {}

return Categories
