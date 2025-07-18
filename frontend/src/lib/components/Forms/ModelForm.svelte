<script lang="ts">
	import { run } from 'svelte/legacy';

	import { setContext, onDestroy } from 'svelte';

	import SuperForm from '$lib/components/Forms/Form.svelte';
	import TextArea from '$lib/components/Forms/TextArea.svelte';
	import TextField from '$lib/components/Forms/TextField.svelte';

	import RiskAssessmentForm from './ModelForm/RiskAssessmentForm.svelte';
	import PerimeterForm from './ModelForm/PerimeterForm.svelte';
	import ThreatForm from './ModelForm/ThreatForm.svelte';
	import RiskScenarioForm from './ModelForm/RiskScenarioForm.svelte';
	import AppliedControlsPoliciesForm from './ModelForm/AppliedControlPolicyForm.svelte';
	import VulnerabilitiesForm from './ModelForm/VulnerabilitiesForm.svelte';
	import RiskAcceptancesForm from './ModelForm/RiskAcceptanceForm.svelte';
	import ReferenceControlsForm from './ModelForm/ReferenceControlForm.svelte';
	import EvidencesForm from './ModelForm/EvidenceForm.svelte';
	import ComplianceAssessmentsForm from './ModelForm/ComplianceAssessmentForm.svelte';
	import AssetsForm from './ModelForm/AssetForm.svelte';
	import RequirementAssessmentsForm from './ModelForm/RequirementAssessmentForm.svelte';
	import EntitiesForm from './ModelForm/EntityForm.svelte';
	import EntityAssessmentForm from './ModelForm/EntityAssessmentForm.svelte';
	import SolutionsForm from './ModelForm/SolutionForm.svelte';
	import RepresentativesForm from './ModelForm/RepresentativeForm.svelte';
	import FrameworksForm from './ModelForm/FrameworkForm.svelte';
	import UsersForm from './ModelForm/UserForm.svelte';
	import SsoSettingsForm from './ModelForm/SsoSettingForm.svelte';
	import FolderForm from './ModelForm/FolderForm.svelte';
	import GeneralSettingsForm from './ModelForm/GeneralSettingForm.svelte';
	import FeatureFlagsSettingForm from './ModelForm/FeatureFlagsSettingForm.svelte';
	import ProcessingForm from './ModelForm/ProcessingForm.svelte';
	import PurposeForm from './ModelForm/PurposeForm.svelte';
	import PersonalDataForm from './ModelForm/PersonalDataForm.svelte';
	import DataSubjectForm from './ModelForm/DataSubjectForm.svelte';
	import DataRecipientForm from './ModelForm/DataRecipientForm.svelte';
	import DataContractorForm from './ModelForm/DataContractorForm.svelte';
	import DataTransferForm from './ModelForm/DataTransferForm.svelte';
	import EbiosRmForm from './ModelForm/EbiosRmForm.svelte';
	import FearedEventForm from './ModelForm/FearedEventForm.svelte';
	import RoToForm from './ModelForm/RoToForm.svelte';
	import StakeholderForm from './ModelForm/StakeholderForm.svelte';
	import AttackPathForm from './ModelForm/AttackPathForm.svelte';
	import SecurityExceptionForm from './ModelForm/SecurityExceptionForm.svelte';
	import FindingForm from './ModelForm/FindingForm.svelte';
	import FindingsAssessmentForm from './ModelForm/FindingsAssessmentForm.svelte';
	import IncidentForm from './ModelForm/IncidentForm.svelte';
	import TimelineEntryForm from './ModelForm/TimelineEntryForm.svelte';
	import TaskTemplateForm from './ModelForm/TaskTemplateForm.svelte';
	import TaskNodeForm from './ModelForm/TaskNodeForm.svelte';
	import BusinessImpactAnalysisForm from './ModelForm/BusinessImpactAnalysisForm.svelte';
	import AssetAssessmentForm from './ModelForm/AssetAssessmentForm.svelte';
	import EscalationThresholdForm from './ModelForm/EscalationThresholdForm.svelte';

	import AutocompleteSelect from './AutocompleteSelect.svelte';

	import { modelSchema } from '$lib/utils/schemas';
	import type { ModelInfo, urlModel, CacheLock } from '$lib/utils/types';
	import { superForm, type SuperValidated } from 'sveltekit-superforms';
	import type { AnyZodObject } from 'zod';
	import { browser } from '$app/environment';
	import { page } from '$app/stores';
	import { m } from '$paraglide/messages';
	import { zod } from 'sveltekit-superforms/adapters';
	import { getSecureRedirect } from '$lib/utils/helpers';
	import { createModalCache } from '$lib/utils/stores';
	import FilteringLabelForm from './ModelForm/FilteringLabelForm.svelte';
	import OperationalScenarioForm from './ModelForm/OperationalScenarioForm.svelte';
	import StrategicScenarioForm from './ModelForm/StrategicScenarioForm.svelte';
	import { goto } from '$lib/utils/breadcrumbs';
	import { safeTranslate } from '$lib/utils/i18n';

	interface Props {
		form: SuperValidated<AnyZodObject>;
		invalidateAll?: boolean; // set to false to keep form data using muliple forms on a page
		taintedMessage?: string | boolean;
		model: ModelInfo;
		context?: string;
		caching?: boolean;
		closeModal?: boolean;
		parent?: any;
		suggestions?: { [key: string]: any };
		cancelButton?: boolean;
		duplicate?: boolean;
		importFolder?: boolean;
		customNameDescription?: boolean;
		additionalInitialData?: any;
		schema?: any;
		object?: Record<string, any>;
		[key: string]: any;
	}

	let {
		form,
		invalidateAll = true,
		taintedMessage = m.taintedFormMessage(),
		model,
		context = 'default',
		caching = false,
		closeModal = false,
		parent = {},
		suggestions = {},
		cancelButton = true,
		duplicate = false,
		importFolder = false,
		customNameDescription = false,
		additionalInitialData = {},
		schema = modelSchema(model.urlModel),
		object = {},
		...rest
	}: Props = $props();

	const URLModel = model.urlModel as urlModel;

	function cancel(): void {
		if (browser) {
			var currentUrl = window.location.href;
			var url = new URL(currentUrl);
			var nextValue = getSecureRedirect(url.searchParams.get('next'));
			if (nextValue) goto(nextValue);
		}
	}
	let shape = $derived(schema.shape || schema._def.schema.shape);
	let updated_fields = new Set();

	function makeCacheLock(): CacheLock {
		let resolve: (_: any) => any = (_) => _;
		const promise = new Promise((res) => {
			resolve = res;
		});
		return { resolve, promise };
	}

	let cacheLocks = $state({});
	run(() => {
		if (shape)
			cacheLocks = Object.keys(shape).reduce((acc, field) => {
				acc[field] = makeCacheLock();
				return acc;
			}, {});
	});

	let formDataCache = $state({});
	let urlModelFromPage = $state();

	run(() => {
		if ($page) {
			urlModelFromPage = `${$page.url}`.replace(/^.*:\/\/[^/]+/, '');
			createModalCache.setModelName(urlModelFromPage);
			if (caching) {
				createModalCache.data[model.urlModel] ??= {};
				formDataCache = createModalCache.data[model.urlModel];
			}
		}
	});

	run(() => {
		if (caching) {
			for (const key of Object.keys(cacheLocks)) {
				cacheLocks[key].resolve(formDataCache[key]);
			}
		}
	});

	let missingConstraints: string[] = $state([]);
	// Context function to update missing constraints
	function updateMissingConstraint(field: string, isMissing: boolean) {
		if (isMissing && !missingConstraints.includes(field)) {
			missingConstraints = [...missingConstraints, field];
		} else if (!isMissing) {
			missingConstraints = missingConstraints.filter((f) => f !== field);
		}
	}
	setContext('updateMissingConstraint', updateMissingConstraint);

	onDestroy(() => {
		missingConstraints = [];
		createModalCache.garbageCollect();
	});

	const _form = superForm(form, {
		dataType: shape?.attachment ? 'form' : 'json',
		enctype: shape?.attachment ? 'multipart/form-data' : 'application/x-www-form-urlencoded',
		invalidateAll,
		applyAction: rest.applyAction ?? true,
		resetForm: rest.resetForm ?? false,
		validators: zod(schema),
		taintedMessage,
		validationMethod: 'auto',
		onUpdated: async ({ form }) => {
			if (form.message?.redirect) {
				goto(getSecureRedirect(form.message.redirect));
			}
			if (form.valid) {
				if (parent && typeof parent.onConfirm === 'function') {
					parent.onConfirm();
				}
				createModalCache.deleteCache(model.urlModel);
			}
		}
	});
</script>

{#if missingConstraints.length > 0}
	<div class="mb-4 p-4 bg-red-100 text-red-700 rounded-lg">
		{m.missingMandatoyObjects1({ model: safeTranslate(model.localName) })}:
		{#each missingConstraints as key}
			<li class="font-bold">{safeTranslate(key)}</li>
		{/each}
		{m.missingMandatoyObjects2()}
	</div>
{/if}
<SuperForm
	class="flex flex-col space-y-3"
	dataType={shape.attachment ? 'form' : 'json'}
	enctype={shape.attachment ? 'multipart/form-data' : 'application/x-www-form-urlencoded'}
	data={form}
	{_form}
	{invalidateAll}
	validators={zod(schema)}
	onUpdated={() => createModalCache.deleteCache(model.urlModel)}
	{...rest}
>
	{#snippet children({ form, data, initialData })}
		<input type="hidden" name="urlmodel" value={model.urlModel} />
		<!--NOTE: Not the cleanest pattern, will refactor-->
		<!--TODO: Refactor-->
		{#if shape.reference_control && !duplicate}
			<AutocompleteSelect
				{form}
				optionsEndpoint="reference-controls"
				optionsExtraFields={[['folder', 'str']]}
				optionsLabelField="auto"
				optionsSuggestions={suggestions['reference_control']}
				field="reference_control"
				cacheLock={cacheLocks['reference_control']}
				bind:cachedValue={formDataCache['reference_control']}
				label={m.referenceControl()}
				nullable={true}
				on:change={async (e) => {
					if (e.detail) {
						await fetch(`/reference-controls/${e.detail}`)
							.then((r) => r.json())
							.then((r) => {
								form.form.update((currentData) => {
									if (
										context === 'edit' &&
										currentData['reference_control'] === initialData['reference_control'] &&
										!updated_fields.has('reference_control')
									) {
										return currentData; // Keep the current values in the edit form.
									}
									updated_fields.add('reference_control');
									return { ...currentData, category: r.category, csf_function: r.csf_function };
								});
							});
					}
				}}
			/>
		{/if}
		{#if shape.name && !customNameDescription}
			<TextField
				{form}
				field="name"
				label={m.name()}
				cacheLock={cacheLocks['name']}
				bind:cachedValue={formDataCache['name']}
				data-focusindex="0"
			/>
		{/if}
		{#if shape.description && !customNameDescription}
			<TextArea
				{form}
				field="description"
				label={m.description()}
				cacheLock={cacheLocks['description']}
				bind:cachedValue={formDataCache['description']}
				data-focusindex="1"
			/>
		{/if}
		{#if URLModel === 'perimeters'}
			<PerimeterForm {form} {model} {cacheLocks} {formDataCache} {initialData} />
		{:else if URLModel === 'folders' || URLModel === 'folders-import'}
			<FolderForm
				{form}
				{importFolder}
				{model}
				{cacheLocks}
				{formDataCache}
				{initialData}
				{object}
			/>
		{:else if URLModel === 'risk-assessments'}
			<RiskAssessmentForm
				{form}
				{model}
				{duplicate}
				{cacheLocks}
				{formDataCache}
				{initialData}
				{object}
				{context}
				{updated_fields}
			/>
		{:else if URLModel === 'threats'}
			<ThreatForm {form} {model} {cacheLocks} {formDataCache} {initialData} />
		{:else if URLModel === 'risk-scenarios'}
			<RiskScenarioForm {form} {model} {cacheLocks} {formDataCache} {initialData} />
		{:else if URLModel === 'applied-controls' || URLModel === 'policies'}
			<AppliedControlsPoliciesForm
				{form}
				{model}
				{duplicate}
				{cacheLocks}
				{formDataCache}
				{schema}
				{initialData}
			/>
		{:else if URLModel === 'vulnerabilities'}
			<VulnerabilitiesForm {form} {model} {cacheLocks} {formDataCache} {initialData} />
		{:else if URLModel === 'risk-acceptances'}
			<RiskAcceptancesForm
				{form}
				{model}
				{cacheLocks}
				{formDataCache}
				{object}
				{initialData}
				{$page}
			/>
		{:else if URLModel === 'reference-controls'}
			<ReferenceControlsForm {form} {model} {cacheLocks} {formDataCache} {initialData} />
		{:else if URLModel === 'evidences'}
			<EvidencesForm {form} {model} {cacheLocks} {formDataCache} {initialData} {object} />
		{:else if URLModel === 'compliance-assessments'}
			<ComplianceAssessmentsForm
				{form}
				{model}
				{cacheLocks}
				{formDataCache}
				{initialData}
				{object}
				{context}
			/>
		{:else if URLModel === 'assets'}
			<AssetsForm {form} {model} {cacheLocks} {formDataCache} {initialData} {object} {data} />
		{:else if URLModel === 'requirement-assessments'}
			<RequirementAssessmentsForm {form} {model} {cacheLocks} {formDataCache} {context} />
		{:else if URLModel === 'entities'}
			<EntitiesForm {form} {model} {cacheLocks} {formDataCache} {initialData} />
		{:else if URLModel === 'entity-assessments'}
			<EntityAssessmentForm {form} {model} {cacheLocks} {formDataCache} {initialData} {data} />
		{:else if URLModel === 'solutions'}
			<SolutionsForm {form} {model} {cacheLocks} {formDataCache} {initialData} />
		{:else if URLModel === 'representatives'}
			<RepresentativesForm {form} {model} {cacheLocks} {formDataCache} {data} />
		{:else if URLModel === 'frameworks'}
			<FrameworksForm {form} {model} {cacheLocks} {formDataCache} />
		{:else if URLModel === 'users'}
			<UsersForm {form} {model} {cacheLocks} {formDataCache} {shape} {context} />
		{:else if URLModel === 'sso-settings'}
			<SsoSettingsForm {form} {model} {cacheLocks} {formDataCache} {data} />
		{:else if URLModel === 'general-settings'}
			<GeneralSettingsForm {form} {model} {cacheLocks} {formDataCache} {data} />
		{:else if URLModel === 'feature-flags'}
			<FeatureFlagsSettingForm {form} {model} {cacheLocks} {formDataCache} {data} />
		{:else if URLModel === 'filtering-labels'}
			<FilteringLabelForm {form} {model} {cacheLocks} {formDataCache} />
		{:else if URLModel === 'business-impact-analysis'}
			<BusinessImpactAnalysisForm
				{form}
				{model}
				{duplicate}
				{cacheLocks}
				{formDataCache}
				{initialData}
				{object}
				{context}
				{updated_fields}
			/>
		{:else if URLModel === 'asset-assessments'}
			<AssetAssessmentForm {form} {model} {cacheLocks} {formDataCache} {context} {initialData} />
		{:else if URLModel === 'escalation-thresholds'}
			<EscalationThresholdForm
				{form}
				{model}
				{cacheLocks}
				{formDataCache}
				{context}
				{initialData}
			/>
		{:else if URLModel === 'processings'}
			<ProcessingForm {form} {model} {cacheLocks} {formDataCache} {context} />
		{:else if URLModel === 'purposes'}
			<PurposeForm {form} {model} {cacheLocks} {formDataCache} {context} {initialData} />
		{:else if URLModel === 'personal-data'}
			<PersonalDataForm {form} {model} {cacheLocks} {formDataCache} {context} {initialData} />
		{:else if URLModel === 'data-subjects'}
			<DataSubjectForm {form} {model} {cacheLocks} {formDataCache} {context} {initialData} />
		{:else if URLModel === 'data-recipients'}
			<DataRecipientForm {form} {model} {cacheLocks} {formDataCache} {context} {initialData} />
		{:else if URLModel === 'data-contractors'}
			<DataContractorForm {form} {model} {cacheLocks} {formDataCache} {context} {initialData} />
		{:else if URLModel === 'data-transfers'}
			<DataTransferForm {form} {model} {cacheLocks} {formDataCache} {context} {initialData} />
		{:else if URLModel === 'ebios-rm'}
			<EbiosRmForm {form} {model} {cacheLocks} {formDataCache} {context} />
		{:else if URLModel === 'feared-events'}
			<FearedEventForm {form} {model} {cacheLocks} {formDataCache} {initialData} />
		{:else if URLModel === 'ro-to'}
			<RoToForm {form} {model} {cacheLocks} {formDataCache} {initialData} {context} />
		{:else if URLModel === 'stakeholders'}
			<StakeholderForm {form} {model} {cacheLocks} {formDataCache} {context} />
		{:else if URLModel === 'strategic-scenarios'}
			<StrategicScenarioForm {form} {model} {cacheLocks} {formDataCache} {initialData} {context} />
		{:else if URLModel === 'attack-paths'}
			<AttackPathForm
				{form}
				{model}
				{cacheLocks}
				{formDataCache}
				{initialData}
				{additionalInitialData}
			/>
		{:else if URLModel === 'operational-scenarios'}
			<OperationalScenarioForm
				{form}
				{model}
				{cacheLocks}
				{formDataCache}
				{initialData}
				{context}
			/>
		{:else if URLModel === 'security-exceptions'}
			<SecurityExceptionForm {form} {model} {cacheLocks} {formDataCache} {initialData} {context} />
		{:else if URLModel === 'findings'}
			<FindingForm {form} {model} {cacheLocks} {formDataCache} {initialData} {context} />
		{:else if URLModel === 'findings-assessments'}
			<FindingsAssessmentForm {form} {model} {cacheLocks} {formDataCache} {initialData} {context} />
		{:else if URLModel === 'incidents'}
			<IncidentForm {form} {model} {cacheLocks} {formDataCache} {initialData} {context} />
		{:else if URLModel === 'timeline-entries'}
			<TimelineEntryForm
				{form}
				{model}
				{cacheLocks}
				{formDataCache}
				initialData={model.initialData}
				{context}
			/>
		{:else if URLModel === 'task-templates'}
			<TaskTemplateForm {form} {model} {cacheLocks} {formDataCache} {initialData} {context} />
		{:else if URLModel === 'task-nodes'}
			<TaskNodeForm {form} {model} {cacheLocks} {formDataCache} {context} />
		{/if}
		<div class="flex flex-row justify-between space-x-4">
			{#if closeModal}
				<button
					class="btn bg-gray-400 text-white font-semibold w-full"
					data-testid="cancel-button"
					type="button"
					onclick={(event) => {
						parent.onClose(event);
						createModalCache.deleteCache(model.urlModel);
					}}>{m.cancel()}</button
				>
				<button
					class="btn preset-filled-primary-500 font-semibold w-full"
					data-testid="save-button"
					type="submit">{m.save()}</button
				>
			{:else}
				{#if cancelButton}
					<button
						class="btn bg-gray-400 text-white font-semibold w-full"
						data-testid="cancel-button"
						type="button"
						onclick={cancel}>{m.cancel()}</button
					>
				{/if}
				<button
					class="btn preset-filled-primary-500 font-semibold w-full"
					data-testid="save-button"
					type="submit">{m.save()}</button
				>
			{/if}
		</div>
	{/snippet}
</SuperForm>
