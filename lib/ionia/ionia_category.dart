class IoniaCategory {
	const IoniaCategory(this.title, this.ids);

	static const allCategories = <IoniaCategory>[
		apparel,
		onlineOnly,
		food,
		entertainment,
		delivery,
		travel];
	static const apparel = IoniaCategory('Apparel', [1]);
	static const onlineOnly = IoniaCategory('Online Only', [13, 43]);
	static const food = IoniaCategory('Food', [4]);
	static const entertainment = IoniaCategory('Entertainment', [5]);
	static const delivery = IoniaCategory('Delivery', [114, 109]);
	static const travel = IoniaCategory('Travel', [12]);

	final String title;
	final List<int> ids;
}
