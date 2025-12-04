package org.gradle.accessors.dm;

import org.gradle.api.NonNullApi;
import org.gradle.api.artifacts.ProjectDependency;
import org.gradle.api.internal.artifacts.dependencies.ProjectDependencyInternal;
import org.gradle.api.internal.artifacts.DefaultProjectDependencyFactory;
import org.gradle.api.internal.artifacts.dsl.dependencies.ProjectFinder;
import org.gradle.api.internal.catalog.DelegatingProjectDependency;
import org.gradle.api.internal.catalog.TypeSafeProjectDependencyFactory;
import javax.inject.Inject;

@NonNullApi
public class RootProjectAccessor extends TypeSafeProjectDependencyFactory {


    @Inject
    public RootProjectAccessor(DefaultProjectDependencyFactory factory, ProjectFinder finder) {
        super(factory, finder);
    }

    /**
     * Creates a project dependency on the project at path ":"
     */
    public Pano360ProjectDependency getPano360() { return new Pano360ProjectDependency(getFactory(), create(":")); }

    /**
     * Creates a project dependency on the project at path ":filepicker"
     */
    public FilepickerProjectDependency getFilepicker() { return new FilepickerProjectDependency(getFactory(), create(":filepicker")); }

    /**
     * Creates a project dependency on the project at path ":pano360demo"
     */
    public Pano360demoProjectDependency getPano360demo() { return new Pano360demoProjectDependency(getFactory(), create(":pano360demo")); }

    /**
     * Creates a project dependency on the project at path ":vrlib"
     */
    public VrlibProjectDependency getVrlib() { return new VrlibProjectDependency(getFactory(), create(":vrlib")); }

}
