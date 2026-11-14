package dev.xdpxi.fakefabricloader;

import java.util.ArrayList;
import java.util.Collections;
import java.util.IdentityHashMap;
import java.util.Map;
import java.util.Set;

import org.quiltmc.loader.api.LoaderValue;
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

        context.ruleContext().removeOption(option);
    }
}
