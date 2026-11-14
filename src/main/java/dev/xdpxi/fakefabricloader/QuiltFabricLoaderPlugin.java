package dev.xdpxi.fakefabricloader;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.IdentityHashMap;
import java.util.Map;
import java.util.Set;

import org.quiltmc.loader.api.LoaderValue;
import org.quiltmc.loader.api.ModMetadata;
import org.quiltmc.loader.api.plugin.QuiltLoaderPlugin;
import org.quiltmc.loader.api.plugin.QuiltPluginContext;
import org.quiltmc.loader.api.plugin.solver.AliasedLoadOption;
import org.quiltmc.loader.api.plugin.solver.LoadOption;
import org.quiltmc.loader.api.plugin.solver.ModLoadOption;

public final class QuiltFabricLoaderPlugin implements QuiltLoaderPlugin {
    private static final String FABRIC_LOADER_ID = "fabricloader";

    private final Set<LoadOption> removed = Collections.newSetFromMap(new IdentityHashMap<>());
    private QuiltPluginContext context;

    @Override
    public void load(QuiltPluginContext context, Map<String, LoaderValue> previousData) {
        this.context = context;
    }

    @Override
    public void unload(Map<String, LoaderValue> data) {
        removed.clear();
    }

    @Override
    public void beforeSolve() {
        if (context == null) {
            return;
        }

        for (ModLoadOption option : new ArrayList<>(context.manager().getAllMods(FABRIC_LOADER_ID))) {
            removeIfProvided(option);
        }
    }

    @Override
    public void onLoadOptionAdded(LoadOption option) {
        removeIfProvided(option);
    }

    private void removeIfProvided(LoadOption option) {
        if (context == null || !(option instanceof AliasedLoadOption) || !(option instanceof ModLoadOption)) {
            return;
        }

        if (!FABRIC_LOADER_ID.equals(((ModLoadOption) option).id()) || !removed.add(option)) {
            return;
        }

        LoadOption provider = ((AliasedLoadOption) option).getTarget();

        if (provider instanceof ModLoadOption) {
            removeProvidedId(((ModLoadOption) provider).metadata());
        }

        context.ruleContext().removeOption(option);
    }

    private static void removeProvidedId(ModMetadata metadata) {
        for (Class<?> type = metadata.getClass(); type != null; type = type.getSuperclass()) {
            Field field;

            try {
                field = type.getDeclaredField("provides");
            } catch (NoSuchFieldException e) {
                continue;
            }

            try {
                field.setAccessible(true);
                Object value = field.get(metadata);

                if (!(value instanceof Collection)) {
                    continue;
                }

                Collection<ModMetadata.ProvidedMod> kept = new ArrayList<>();

                for (Object entry : (Collection<?>) value) {
                    ModMetadata.ProvidedMod provided = (ModMetadata.ProvidedMod) entry;

                    if (!FABRIC_LOADER_ID.equals(provided.id())) {
                        kept.add(provided);
                    }
                }

                field.set(metadata, Collections.unmodifiableCollection(kept));
                return;
            } catch (ReflectiveOperationException | RuntimeException e) {
                throw new IllegalStateException("Cannot remove the provided id '" + FABRIC_LOADER_ID + "' from " + metadata.id(), e);
            }
        }

        throw new IllegalStateException("Cannot find the provided ids of " + metadata.id() + " (" + metadata.getClass().getName() + ")");
    }
}
