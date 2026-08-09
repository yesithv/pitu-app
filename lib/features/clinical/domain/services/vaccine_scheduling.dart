/// Sugerencia de la próxima dosis de una vacuna (RF-19): por defecto, un año
/// después de la fecha de aplicación. El usuario puede editarla en el formulario.
/// Se aísla como función pura para poder validarla con pruebas unitarias.
DateTime suggestNextVaccineDose(DateTime appliedDate) =>
    DateTime(appliedDate.year + 1, appliedDate.month, appliedDate.day);
